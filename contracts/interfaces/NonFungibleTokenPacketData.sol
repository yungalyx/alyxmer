pragma solidity ^0.8.9;
// this must be json encoded during the packet send
// interface NonFungibleTokenPacketData {
//   classId: string
//   classUri: string
//   classData: string
//   tokenIds: string[]
//   tokenUris: string[]
//   tokenData: string[]
//   sender: string
//   receiver: string
//   memo: string
// }

struct NonFungibleTokenPacketData {
  address classId;
  string hops;
  string classUri;
  string classData;
  uint256 tokenId;
  string tokenUri;
  string tokenData;
  address sender;
  address receiver;
  string memo;
}

enum NonFungibleTokenPacketAcknowledgement {
  NonFungibleTokenPacketSuccess,
  NonFungibleTokenPacketError
}

// type NonFungibleTokenPacketAcknowledgement =
//   | NonFungibleTokenPacketSuccess
//   | NonFungibleTokenPacketError

struct NonFungibleTokenPacketSuccess {
  // This is binary 0x01 base64 encoded
  string success; // "AQ=="
}

struct NonFungibleTokenPacketError {
  string error;
}

// interface ModuleState {
//   channelEscrowAddresses: Map<Identifier, string>
// }