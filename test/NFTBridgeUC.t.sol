// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../contracts/NFTBridgeUC.sol";
import "../contracts/NFT.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTBridgeTest is Test {

  uint256 baseMainnet;
  uint256 baseSepolia;
  uint256 optimismSepolia;


    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function setUp() public {

      baseMainnet = vm.createFork("https://mainnet.base.org");
      baseSepolia = vm.createFork("https://sepolia.base.org");
      optimismSepolia = vm.createFork("https://sepolia.optimism.io");        
        
    }

    

    function test_ping_pong() public {
        vm.selectFork(baseSepolia);
        // vm.chainId(84532);

        NFTBridgeUC baseBridge = new NFTBridgeUC(
            0xfC1d3E02e00e0077628e8Cc9edb6812F95Db05dC
        ); // this is a random address, just testing NFT related things
        vm.makePersistent(address(baseBridge));
        assertEq(vm.activeFork(), baseSepolia);

        vm.selectFork(optimismSepolia);
        // vm.chainId(11155420);
        assertEq(vm.activeFork(), optimismSepolia);

        NFTBridgeUC opBridge = new NFTBridgeUC(
            0x58f1863F75c9Db1c7266dC3d7b43832b58f35e83
        );
        vm.makePersistent(address(opBridge));

        assert(vm.isPersistent(address(baseBridge)));
        assert(vm.isPersistent(address(opBridge)));

        vm.selectFork(baseSepolia);

        assertEq(baseBridge.getChainId(), 84532);

        vm.selectFork(optimismSepolia);

        assertEq(opBridge.getChainId(), 11155420);

        // assertNotEq(opBridge.getChainId(), baseBridge.getChainId());
    }

    function test_transfer_real() public {

      // deployments on base
      vm.selectFork(baseSepolia);

     
      NFTBridgeUC baseBridge = new NFTBridgeUC(0xfC1d3E02e00e0077628e8Cc9edb6812F95Db05dC); // this is a random address, just testing NFT related things 
    
      vm.makePersistent(address(baseBridge));

      // deployments on optimism
      vm.selectFork(optimismSepolia);
      NFTBridgeUC opBridge = new NFTBridgeUC(0x58f1863F75c9Db1c7266dC3d7b43832b58f35e83);
      NFT myNFT = new NFT();
      myNFT.Mint();
  
      vm.makePersistent(address(myNFT));

      console.log("minted NFT");
 
      
      bytes32 channelId = stringToBytes32('channel-11');
      opBridge.configureBridge(84532, address(baseBridge), channelId);
      vm.makePersistent(address(opBridge));
        
      // approve and transfer
      address owner = IERC721(address(myNFT)).ownerOf(0);
      IERC721(address(myNFT)).approve(address(opBridge), 0);

      opBridge.initiateSend(address(myNFT), 0, owner, 84532); // send to base sepolia 


      console.log("made it here");

      
      assertEq(IERC721(address(myNFT)).ownerOf(0), address(opBridge));



      // check if successful on Sepolia
      vm.selectFork(baseSepolia);

      assertEq(opBridge.ping(), "pong");

  
   
    }


    function test_return_failed() public {
      
      
    }

    function test_ack_failed() public {

      vm.selectFork(baseSepolia);

      NFTBridgeUC baseBridge = new NFTBridgeUC(0xfC1d3E02e00e0077628e8Cc9edb6812F95Db05dC); 

      bytes32 channelId = stringToBytes32('channel-11');
      bytes memory padloay = abi.encode("nothing");
      uint64 timeoutTimestamp = uint64((block.timestamp + 3600000) * 1000000000);

      bytes32 to = hex"014a34";
    
  
      IbcUniversalPacketSender(0xfC1d3E02e00e0077628e8Cc9edb6812F95Db05dC).sendUniversalPacket(
          channelId, to, padloay, timeoutTimestamp
      );



    }

    function test_transfer_voucher() public {

    }

}