//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";
import "./interfaces/NonFungibleTokenPacketData.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "forge-std/console.sol";



contract NFTBridgeUC is UniversalChanIbcApp, ERC721, IERC721Receiver {
    // application specific state


    constructor(address _middleware) UniversalChanIbcApp(_middleware) ERC721("PolymerBridgeVoucher", "PBV") {}

    // APPLICATION SPECIFIC LOGIC 


    function initiateSend(address _nftContract, uint256 _tokenId) external {
      require(_nftContract != address(this), "Cannot send from same contract");

      console.log("made it here");



      // NonFungibleTokenPacketData nftpd = NonFungibleTokenPacketData(
      //   classId,
      //   IERC721(_collection).contractURI,
      //   nft.GetClass(classId).GetData(),
      //   tokenIds,
      //   tokenUris,
      //   tokenData,
      //   sender,
      //   receive,
      // )


      if (isNFTOwner(_nftContract, _tokenId, msg.sender)) { // real
        // escrow
        // send 
  
        ERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

        // NonFungibleTokenPacketData nftpd = NonFungibleTokenPacketData();
        // sendUniversalPacket(nftpd);

    


      } else if (isNFTOwner(address(this), _tokenId, msg.sender)) { // voucher
        // burn 
        // send 
        _burn(_tokenId);
        // sendUniversalPacket();
        // createOutgoingPacket();
      } else {
        console.log("Caller does not own");
        revert("Caller does not own specified NFT");
      }
    }

    function isNFTOwner(address _nftContract, uint256 _tokenId, address _owner) private view returns (bool) {
      console.log(_nftContract);
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
  
    

    


    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external pure returns (bytes4) {

      return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    }

    

    


    // When a non-fungible token is sent back toward its source,
    // the bridge module burns the token on the sending chain
    // and unescrows the corresponding locked token on the receiving chain.

    // I BEFORE E, EXCEPT AFTER C 
    function _receive(NonFungibleTokenPacketData memory nftpd) internal {

      // either unescrows on base 


      // or mints a voucher on dst

      
      // uint256 newID = (uint256(uint160(nftpd.classId)) << 128) | nftpd.tokenId;
      // _safeMint(nftpd.receiver, newID);
      // return newID;

    }

  // SUB-PROTOCOLS 



    function CreateOrUpdateClass() public {

    }


    
    function Mint() public {


    }


    function Burn() public {



    }

    function GetOwner() public {

    }

    function getNFT() public {

    }

    function getClass() public {

    }

    function refundToken(UniversalPacket calldata packet) private {

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


    


//     // IBC logic

  function sendUniversalPacket(
    NonFungibleTokenPacketData calldata nftpd,
    address destPortAddr, 
    bytes32 channelId, 
    uint64 timeoutSeconds
  ) internal {

    // string prefix = sourcePort + "/" + sourceChannel;
    // bool source = classId.slice(0, len(prefix))!== prefix;

    

    bool source = true;
    if (source) {
      IERC721(nftpd.classId).safeTransferFrom(msg.sender, address(this), nftpd.tokenId);
    } else { 
      _burn(nftpd.tokenId);
    }
    // token = nft.GetNFT(classId, tokenId)

    // tokenUris.push(token.GetUri())
    // tokenData.push(token.GetData())

      // increment();
      // bytes memory payload = abi.encode(msg.sender, counter);

      bytes memory payload = abi.encode(nftpd);

      
      uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

      IbcUniversalPacketSender(mw).sendUniversalPacket(
          channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
      );
  }

//     NonFungibleTokenPacketData data = NonFungibleTokenPacketData{
//     classId,
//     nft.GetClass(classId).GetUri(),
//     nft.GetClass(classId).GetData(),
//     tokenIds,
//     tokenUris,
//     tokenData,
//     sender,
//     receive
//   }
  
  
//   function createOutgoingPacket(
//     classId: string,
//     tokenIds: string[],
//     sender: string,
//     receiver: string,
//     destPort: string,
//     destChannel: string,
//     sourcePort: string,
//     sourceChannel: string,
//     timeoutHeight: Height,
//     timeoutTimestamp: uint64): uint64 {
//     prefix = sourcePort + '/' + sourceChannel
//     // we are source chain if classId is not prefixed with sourcePort and sourceChannel
//     source = classId.slice(0, len(prefix)) !== prefix
//     tokenUris = []
//     tokenData = []
//   for (let tokenId in tokenIds) {
//     // ensure that sender is token owner
//     abortTransactionUnless(sender === nft.GetOwner(classId, tokenId))
//     if source { // we are source chain, escrow token
//       nft.Transfer(classId, tokenId, channelEscrowAddresses[sourceChannel], null)
//     } else { // we are sink chain, burn voucher
//       nft.Burn(classId, tokenId)
//     }
//     token = nft.GetNFT(classId, tokenId)
//     tokenUris.push(token.GetUri())
//     tokenData.push(token.GetData())
//   }
//   NonFungibleTokenPacketData data = NonFungibleTokenPacketData{
//     classId,
//     nft.GetClass(classId).GetUri(),
//     nft.GetClass(classId).GetData(),
//     tokenIds,
//     tokenUris,
//     tokenData,
//     sender,
//     receive
//   }
//   sequence = Handler.sendPacket(
//     getCapability("port"),
//     sourcePort,
//     sourceChannel,
//     timeoutHeight,
//     timeoutTimestamp,
//     protobuf.marshal(data) // protobuf-marshalled bytes of packet data
//   )
//   return sequence
// }

  

      /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet)
        external
        override
        onlyIbcMw
        returns (AckPacket memory ackPacket)
    {
        // recvedPackets.push(UcPacketWithChannel(channelId, packet));

        NonFungibleTokenPacketData memory nftpd = abi.decode(packet.appData, (NonFungibleTokenPacketData));
        // counterMap[c] = payload;

        _receive(nftpd);

        return AckPacket(true, abi.encode("Ackonoledged"));
    }

    // function onRecvPacket(packet: Packet) {
    //   NonFungibleTokenPacketData data = packet.data
    //   // construct default acknowledgement of success
    //   NonFungibleTokenPacketAcknowledgement ack = NonFungibleTokenPacketAcknowledgement{true, null}
    //   err = ProcessReceivedPacketData(data)
    //   if (err !== null) {
    //     ack = NonFungibleTokenPacketAcknowledgement{false, err.Error()}
    //   }
    //   return ack
    // }

  // function ProcessReceivedPacketData(data: NonFungibleTokenPacketData) {
  //   prefix = data.sourcePort + '/' + data.sourceChannel
  //   // we are source chain if classId is prefixed with packet's sourcePort and sourceChannel
  //   source = data.classId.slice(0, len(prefix)) === prefix
  //   for (var i in data.tokenIds) {
  //     if source { // we are source chain, un-escrow token to receiver
  //       nft.Transfer(data.classId.slice(len(prefix)), data.tokenIds[i], data.receiver, data.tokenData[i])
  //     } else { // we are sink chain, mint voucher to receiver
  //       prefixedClassId = data.destPort + '/' + data.destChannel + '/' + data.classId
  //       nft.CreateOrUpdateClass(prefixedClassId, data.classUri, data.classData)
  //       nft.Mint(prefixedClassId, data.tokenIds[i], data.tokenUris[i], data.tokenData[i], data.receiver)
  //     }
  //   }
  // }


  /**
    * @dev Packet lifecycle callback that implements packet acknowledgment logic.
    *      MUST be overriden by the inheriting contract.
    * 
    * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
    */
  function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket calldata packet, AckPacket calldata ack) external override onlyIbcMw {
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
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // do logic
    }


// function onTimeoutPacketClose(packet: Packet) {
//   // can't happen, only unordered channels allowed
// }



}