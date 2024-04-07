pragma solidity ^0.8.9;

import {IbcUtils, UniversalPacket, AckPacket} from "@openibc/contracts/libs/Ibc.sol";
import {IbcMwUser, IbcUniversalPacketReceiver, IbcUniversalPacketSender} from "@openibc/contracts/interfaces/IbcMiddleware.sol";
import "./base/UniversalChanIbcApp.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "forge-std/console.sol";

/**
 * @title nft-mint
 * @dev Implements minting process,
 * and ability to send cross-chain instruction to mint NFT on counterparty
 */
contract DAONFT is UniversalChanIbcApp, ERC721, ERC721Burnable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    error UnauthorizedIbcMiddleware();
    error ackDataTooShort();
    error ackAddressMismatch();

    // token id
    Counters.Counter private currentTokenId;
    // Mapping for active tokens
    mapping(uint256 => bool) private _activeTokens;

    // mapping for token URIs
    // If the token is mint by user, the new token uri is the same as token id
    // If the token is mint through bridge, we will map the original contract's token id as the new token uri.
    mapping(uint256 => uint256) private _tokenURIs;

    // Base URI
    string private _baseURIextended;

    // Maintainer Address
    address public maintainer;

    // IBC Specific
    event NFTMint(address owner, uint tokenId, uint tokenURI);
    event MintedOnRecv(bytes32 channelId, uint64 sequence, uint256 newTokenId);

    constructor(
        address _middleware
    ) UniversalChanIbcApp(_middleware) ERC721("DAONFT", "DT") {
        maintainer = msg.sender;
    }

    // URI Settings
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev Remapping for the token id to match the true token URI
     * @param tokenId the tokenid of the current NFT
     * @param _tokenURI the mapping tokenURI for the current token id
     */
    function _setTokenURI(uint256 tokenId, uint256 _tokenURI) internal virtual {
        //require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * User Mint NFT function
     */
    function mint() external returns (uint256) {
        address _to = msg.sender;
        currentTokenId.increment();
        uint256 tokenId = currentTokenId.current();
        _mint(_to, tokenId);
        _setTokenURI(tokenId, tokenId); //For user mint NFT, token uri is the same as tokenId
        return tokenId;
    }

    /**
     * @dev Mint the NFT based on the info from the received packet
     * @param recipient the recever address
     * @param originalTokenURI original token uri from the send contract
     */
    function mintRceived(
        address recipient,
        uint256 originalTokenURI
    ) internal returns (uint256) {
        currentTokenId.increment();
        uint256 tokenId = currentTokenId.current();
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, originalTokenURI);
        return tokenId;
    }

    // IBC methods

    /**
     * @dev Sends a packet with NFT info over a specified channel.
     * @param receiver the receiver of NFT token in the destination contract
     * @param destPortAddr the address of the destination
     * @param channelId The ID of the channel to send the packet to.
     * @param tokenId the token to be sent
     * @param timeoutSeconds The timeout in seconds (relative).
     */
    function sendPacket(
        address receiver,
        address destPortAddr,
        bytes32 channelId,
        uint256 tokenId,
        uint64 timeoutSeconds
    ) external {
        address sender = msg.sender;
        address owner = ownerOf(tokenId);
        require(sender == owner, "owner need to be the sender");
        // get the tokenURI
        uint256 originalTokenURI = _tokenURIs[tokenId];
        bytes memory payload = abi.encodePacked(receiver, originalTokenURI);
        // send to the destination port
        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId,
            IbcUtils.toBytes32(destPortAddr),
            payload,
            timeoutSeconds
        );
        // TODO:
        // burn(tokenId);
    }

    /**
     *  When Receive the Packet
     * @param channelId the id of the receving channel
     * @param packet data send through ibc
     */
    function onRecvUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));

        // Decode the packet data
        if (packet.appData.length > 20) {
            address receiver = address(bytes20(packet.appData[0:20]));
            uint256 originalTokenURI = uint256(bytes32(packet.appData[20:]));
            // // Mint the NFT
            uint256 newTokenId = mintRceived(receiver, originalTokenURI);
        }

        return
            AckPacket(
                true,
                abi.encodePacked(
                    address(this),
                    IbcUtils.toAddress(packet.srcPortAddr),
                    "ack-",
                    packet.appData
                )
            );
    }

    function onUniversalAcknowledgement(
        bytes32 channelId,
        UniversalPacket memory packet,
        AckPacket calldata ack
    ) external override onlyIbcMw {
        // verify packet's destPortAddr is the ack's first encoded address. See generateAckPacket())
        if (ack.data.length < 20) revert ackDataTooShort();
        address ackSender = address(bytes20(ack.data[0:20]));
        if (IbcUtils.toAddress(packet.destPortAddr) != ackSender)
            revert ackAddressMismatch();
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));
    }

    function onTimeoutUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        //require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI.toString();
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (_tokenURI > 0) {
            return string(abi.encodePacked(base, _tokenURI.toString()));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function burn(uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner,
            "ERC721: caller is not owner nor approved"
        );

        _burn(tokenId);
        _activeTokens[tokenId] = false;
    }

    // For testing only; real dApps should implment their own ack logic
    function generateAckPacket(
        bytes32,
        address srcPortAddr,
        bytes calldata appData
    ) external view returns (AckPacket memory ackPacket) {
        return
            AckPacket(
                true,
                abi.encodePacked(this, srcPortAddr, "ack-", appData)
            );
    }
}
