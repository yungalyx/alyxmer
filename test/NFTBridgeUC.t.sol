// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../contracts/NFTBridgeUC.sol";
import "../contracts/NFT.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTBridgeTest is Test {
    NFTBridgeUC public nftBridge;
    NFT public myNFT;

    string BASE_RPC_URL = vm.envString("BASE_RPC_URL");
    // string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL");

    function setUp() public {

      //MAINNET_RPC_URL = 'https://eth-mainnet.g.alchemy.com/v2/ALCHEMY_KEY'
    
      
        // console.log(vm.activeFork());
        uint256 forkId = vm.createFork("https://mainnet.base.org");
        // uint256 fork2Id = vm.createFork(BASE_RPC_URL);
        
        
        // vm.selectFork(forkId);

  

        nftBridge = new NFTBridgeUC(0xFa658e6aE02eC4210F76033B0Ea365517B797cCE); // this is a random address, just testing NFT related things 

    }

    function testFork() public {
      assertEq(vm.activeFork(), 0);
    }

    function test_valid() public {

        myNFT = new NFT();
        myNFT.Mint();
        
        address owner = IERC721(address(myNFT)).ownerOf(0);

        nftBridge.initiateSend(address(myNFT), 0);
   
        //address owner = IERC721(address(0xA449b4f43D9A33FcdCF397b9cC7Aa909012709fD)).ownerOf(4728);
   

        

    //   //vm.startPrank(0x5D0aC389c669D6EFE3BA96B9878d8156f180C539);
    //   // console.log("prank started");

      
    //   // OFsNFT.approve(address(nftbuc), 643);
    //   // console.log("nft approved");
    //   // nftbuc.send(0xA449b4f43D9A33FcdCF397b9cC7Aa909012709fD, 643); // base gods address, 


    //   vm.stopPrank();
   
    }

}