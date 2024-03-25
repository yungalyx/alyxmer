// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../contracts/NFTBridgeUC.sol";
import "../contracts/NFT.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {Dispatcher} from "@openibc/contracts/core/Dispatcher.sol";
import "@openibc/contracts/core/OpConsensusStateManager.sol";
import "@openibc/contracts/utils/DummyConsensusStateManager.sol";
import {UniversalChannelHandler} from "@openibc/contracts/core/UniversalChannelHandler.sol";

contract NFTBridgeTest is Test {
    uint256 baseMainnet;
    uint256 baseSepolia;
    uint256 optimismSepolia;
    // For testing
    address optimismSepoliaUniversalChannelHandler =
        0xC3318ce027C560B559b09b1aA9cA4FEBDDF252F5;
    address baseSepoliaUniversalChannelHandler =
        0x5031fb609569b67608Ffb9e224754bb317f174cD;
    string optimismSepoliaUniversalChannelName = "channel-10";
    string baseSepoliaUniversalChannelName = "channel-11";

    function stringToBytes32(
        string memory source
    ) public pure returns (bytes32 result) {
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
            optimismSepoliaUniversalChannelHandler
        );
        vm.makePersistent(address(opBridge));

        assert(vm.isPersistent(address(baseBridge)));
        assert(vm.isPersistent(address(opBridge)));

        vm.selectFork(baseSepolia);

        assertEq(baseBridge.getChainId(), 84532);

        vm.selectFork(optimismSepolia);

        assertEq(opBridge.getChainId(), 11155420);
    }

    function test_transfer_real() public {
        // deployments on base
        vm.selectFork(baseSepolia);
        NFTBridgeUC baseBridge = new NFTBridgeUC(
            baseSepoliaUniversalChannelHandler
        );
        vm.makePersistent(address(baseBridge));

        // deployments on optimism
        vm.selectFork(optimismSepolia);
        NFTBridgeUC opBridge = new NFTBridgeUC(
            optimismSepoliaUniversalChannelHandler
        );
        //  Set the Channel for Op
        bytes32 channelId = stringToBytes32(
            optimismSepoliaUniversalChannelName
        );
        opBridge.configureBridge(84532, address(baseBridge), channelId);
        vm.makePersistent(address(opBridge));

        // Mint NFT
        NFT myNFT = new NFT();
        myNFT.Mint();
        vm.makePersistent(address(myNFT));
        console.log("minted NFT");

        // approve and transfer
        address owner = IERC721(address(myNFT)).ownerOf(0);
        IERC721(address(myNFT)).approve(address(opBridge), 0);

        // From Optimsim to Base
        Vm.Log[] memory entries;
        vm.recordLogs();
        opBridge.initiateSend(address(myNFT), 0, owner, 84532); // send to base sepolia
        // catch the emit event data for Base
        entries = vm.getRecordedLogs();
        Vm.Log memory emitEvent;
        bytes memory payload = entries[1].data;
        console.logBytes(payload);

        // Base handler call onRecvPacket

        // Fake Base Received
        vm.selectFork(baseSepolia);
        address universalFakeHandler = address(1);
        vm.prank(universalFakeHandler);
        UniversalPacket memory packet = UniversalPacket({
            srcPortAddr: stringToBytes32("0x00"),
            appData: payload,
            destPortAddr: stringToBytes32("0x00"),
            mwBitmap: 0
        });
        baseBridge.onRecvUniversalPacketTest(
            stringToBytes32(optimismSepoliaUniversalChannelName),
            packet
        );

        // dispatcher.onRecvPacket

        console.log("made it here");

        assertEq(IERC721(address(myNFT)).ownerOf(0), address(opBridge));

        // check if successful on Sepolia
        vm.selectFork(baseSepolia);

        assertEq(opBridge.ping(), "pong");
    }

    function test_return_failed() public {}

    function test_ack_failed() public {
        vm.selectFork(baseSepolia);

        NFTBridgeUC baseBridge = new NFTBridgeUC(
            0xfC1d3E02e00e0077628e8Cc9edb6812F95Db05dC
        );

        bytes32 channelId = stringToBytes32("channel-11");
        bytes memory padloay = abi.encode("nothing");
        uint64 timeoutTimestamp = uint64(
            (block.timestamp + 3600000) * 1000000000
        );

        bytes32 to = hex"014a34";

        IbcUniversalPacketSender(0xfC1d3E02e00e0077628e8Cc9edb6812F95Db05dC)
            .sendUniversalPacket(channelId, to, padloay, timeoutTimestamp);
    }

    function test_transfer_voucher() public {}
}
