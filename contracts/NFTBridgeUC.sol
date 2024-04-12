//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";
import "./interfaces/NonFungibleTokenPacketData.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "forge-std/console.sol";

contract NFTBridgeUC is UniversalChanIbcApp, ERC721, IERC721Receiver {
    // application specific state

    address private maintainer;

    event NFTPayload(bytes payload);

    mapping(uint64 => address) private destPortAddr;
    mapping(uint64 => bytes32) private channelId;

    constructor(
        address _middleware
    ) UniversalChanIbcApp(_middleware) ERC721("PolymerBridgeVoucher", "PBV") {
        maintainer = msg.sender;
    }

    // Verify the Send and Receive Flow

    function initiateSend(
        address _nftContract,
        uint256 _tokenId,
        address _receiver,
        uint64 _chainId
    ) external {
        IERC721Metadata nft = IERC721Metadata(_nftContract);

        NonFungibleTokenPacketData memory nftpd = NonFungibleTokenPacketData({
            classId: _nftContract,
            classAddress: _nftContract, 
            classUri: nft.name(),
            classData: "",
            tokenId: _tokenId,
            tokenUri: nft.tokenURI(_tokenId),
            tokenData: "",
            sender: msg.sender,
            receiver: _receiver,
            memo: ""
        });

        if (isNFTOwner(_nftContract, _tokenId, msg.sender)) {
            // real

            _sendUniversalPacket(nftpd, _chainId);
        } else if (isNFTOwner(address(this), _tokenId, msg.sender)) {
            // voucher

            _sendUniversalPacket(nftpd, _chainId);
        } else {
            revert("Caller does not own specified NFT");
        }
    }

    function isNFTOwner(
        address _nftContract,
        uint256 _tokenId,
        address _owner
    ) private view returns (bool) {
        return IERC721(_nftContract).ownerOf(_tokenId) == _owner;
    }

    //  bytes memory dataURI = abi.encodePacked(
    //       '{',
    //           '"name": "My721Token #', tokenId.toString(), '"',
    //           // Replace with extra ERC721 Metadata properties
    //       '}'
    //   );

    //  return string(
    //       abi.encodePacked(
    //           "data:application/json;base64,",
    //           Base64.encode(dataURI)
    //       )
    //   );

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    // example of bytes32: 0x626c756500000000000000000000000000000000000000000000000000000000
    function _receive(
        bytes32 srcChannel,
        bytes32 srcPort,
        NonFungibleTokenPacketData memory nftpd
    ) internal {
      
        string memory port = bytes32ToString(srcPort);
        string memory channel = bytes32ToString(srcChannel);
        string memory prefix = string(abi.encodePacked(port, "/", channel));
        

        bool source = _compare(substring(nftpd.classId, 0, bytes(prefix).length), prefix);

        // if (nftpd.hops) {
        //     // createUpdateClass;
        //     _mint(nftpd.reciever, 2);
        // } else {
        //     IERC721(nftpd.classId).transferFrom(
        //         address(this),
        //         nftpd.receiver,
        //         nftpd.tokenId
        //     );
        // }
          // we are source chain if classId is prefixed with packet's sourcePort and sourceChannel

          if (source) {
            // todo: determine the tokenId
        
            IERC721(nftpd.classAddress).transferFrom(address(this), nftpd.receiver, nftpd.tokenId);

          } else {
             // prefixedClassId = data.destPort + '/' + data.destChannel + '/' + data.classId
            // string memory prefix2 = string(abi.encodePacked(address(this), "/", ))
            _mint(nftpd.reciever, combineUintAndAddress(nftpd.tokenId, nftpd.classAddress));
          }
         

        //   for (var i in data.tokenIds) {
        //     if source { // we are source chain, un-escrow token to receiver
        //       nft.Transfer(data.classId.slice(len(prefix)), data.tokenIds[i], data.receiver, data.tokenData[i])
        //     } else { // we are sink chain, mint voucher to receiver
        //       prefixedClassId = data.destPort + '/' + data.destChannel + '/' + data.classId
        //       nft.CreateOrUpdateClass(prefixedClassId, data.classUri, data.classData)
        //       nft.Mint(prefixedClassId, data.tokenIds[i], data.tokenUris[i], data.tokenData[i], data.receiver)
        //     }
        //   }
    }

    // SUB-PROTOCOLS

    // this needs to update hops before / after sending
    function CreateOrUpdateClass() public {}
   

    function Mint(string classId, uint256 tokenId, string tokenURI, string tokenData, string reciever) private pure {
    // creates a new NFT identified by <classId,tokenId>
    // receiver becomes owner of the newly minted NFT

    }

    // destroys the NFT identified by <classId,tokenId>
    function Burn(string classId, uint256 tokenId) private pure {

    }


    function GetOwner(uint256 tknid) public pure {
        return ownerOf(tknid);
    }

    //
    function getNFT(address classId, uint256 tokenId) public {

    }

    // returns NFT Class identified by classId
    function getClass() public {}

    function refundToken(UniversalPacket calldata packet) private {
        NonFungibleTokenPacketData memory nftpd = abi.decode(
            packet.appData,
            (NonFungibleTokenPacketData)
        );

        IERC721(nftpd.classId).transferFrom(
            address(this),
            nftpd.receiver,
            nftpd.tokenId
        );
        // _burn()
        // _burn(1); // this may revert if not exists.
    }

    // PACKET RELAY

    //   function refundToken(packet: Packet) {
    //     NonFungibleTokenPacketData data = packet.data
    //     prefix = data.sourcePort + '/' + data.sourceChannel
    //   // we are the source if the classId is not prefixed with the packet's sourcePort and sourceChannel
    //     source = data.classId.slice(0, len(prefix)) !== prefix
    //     for (var i in data.tokenIds) {
    //       if source { // we are source chain, un-escrow token back to sender
    //         nft.Transfer(data.classId, data.tokenIds[i], data.sender, null)
    //       } else { // we are sink chain, mint voucher back to sender
    //         nft.Mint(data.classId, data.tokenIds[i], data.tokenUris[i], data.tokenData[i], data.sender)
    //       }
    //     }
    //   }

    // Testing

    function onRecvUniversalPacketTest(
        bytes32 _channelId,
        UniversalPacket calldata packet
    ) external returns (AckPacket memory ackPacket) {
        // recvedPackets.push(UcPacketWithChannel(channelId, packet));
        console.log("success");

        bytes memory payload = packet.appData;
        console.log("success1");
        NonFungibleTokenPacketData memory nftpd = abi.decode(
            payload,
            (NonFungibleTokenPacketData)
        );

        console.log("success2");
        console.log(nftpd.tokenId);

        _receive(packet.srcPortAddr, nftpd);

        return AckPacket(true, abi.encode("Acknowledged"));
    }

    //     // IBC logic

    function _sendUniversalPacket(
        NonFungibleTokenPacketData memory nftpd,
        uint64 _chain
    ) internal {
        // string prefix = sourcePort + "/" + sourceChannel;
        // bool source = classId.slice(0, len(prefix))!== prefix;

        require(channelId[_chain] != bytes32(0x0), "chain not configured");

        if (_compare(nftpd.hops, "")) {
            IERC721(nftpd.classId).safeTransferFrom(
                msg.sender,
                address(this),
                nftpd.tokenId
            );
        } else {
            _burn(nftpd.tokenId);
        }
        // token = nft.GetNFT(classId, tokenId)
        // increment();
        // bytes memory payload = abi.encode(msg.sender, counter);

        bytes memory payload = abi.encode(nftpd);

        emit NFTPayload(payload);

        uint64 timeoutTimestamp = uint64(
            (block.timestamp + 3600000) * 1000000000
        );

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId[_chain],
            IbcUtils.toBytes32(destPortAddr[_chain]),
            payload,
            timeoutTimestamp
        );
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param _channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(
        bytes32 _channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
        // recvedPackets.push(UcPacketWithChannel(channelId, packet));

        NonFungibleTokenPacketData memory nftpd = abi.decode(
            packet.appData,
            (NonFungibleTokenPacketData)
        );

        _receive(_channelId, packet.srcPortAddr, nftpd);

        return AckPacket(true, abi.encode("Acknowledged"));
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onUniversalAcknowledgement(
        bytes32 _channelId,
        UniversalPacket calldata packet,
        AckPacket calldata ack
    ) external override onlyIbcMw {
        // ackPackets.push(ack);

        if (!ack.success) refundToken(packet);

        // (uint64 _counter) = abi.decode(ack.data, (uint64));

        // if (_counter != counter) {
        //   resetCounter();
        // }
    }

    // When a packet times out, tokens represented in the packet are either unescrowed or
    // minted back to the sender appropriately --
    // depending on whether the tokens are being moved away from or back toward their source.
    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param _channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(
        bytes32 _channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(_channelId, packet));
        // do logic
    }

    // HELPERS

    function _compare(
        string memory str1,
        string memory str2
    ) internal pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }

    function substring(string calldata str, uint startIndex, uint endIndex) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }


    function toString(address _addr) private pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        
        return string(str);
    }

     function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function combineUintAndAddress(uint256 uintPart, address addressPart) public pure returns (uint256) {
        return uint256(uintPart) * 2**160 + uint256(uint160(addressPart));
    }

    function extractUintAndAddress(uint256 combinedValue) public pure returns (uint256 uintPart, address addressPart) {
        uintPart = combinedValue / 2**160; // Extracting the uint256 part
        addressPart = address(uint160(combinedValue & ((1 << 160) - 1))); // Extracting the address part
    }





    function getChainId() public view returns (uint) {
        return block.chainid;
    }

    // function onTimeoutPacketClose(packet: Packet) {
    //   // can't happen, only unordered channels allowed
    // }
}
