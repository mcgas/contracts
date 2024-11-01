// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { MyOApp } from "../contracts/MyOApp.sol";
import { console } from "forge-std/Script.sol";

contract DeployMyOApp is Script {
    // address[] public configurationAddresses;
    // address[] public priceFeedAddresses;

    function run() external returns (MyOApp, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        address ownerAddress = address(0xcC9E163Fcd646DCa936268C87Eed7503469acAce);

        (
            uint32 endPointID,
            address endpointV2,
            address sendUln302,
            address receiveUln302,
            address sendUln301,
            address receiveUln301,
            address lZExecutor,
            uint256 deployerKey
        ) = helperConfig.activeLZConfig();

        // uint256 addressTest = uint(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);

        // console.log("addressTest", addressTest);

        console.log("deployerKey", deployerKey);
        console.log("endPointID", endPointID);

        vm.startBroadcast(deployerKey);
        MyOApp myOApp = new MyOApp(endpointV2, ownerAddress);
        // Call on both sides per pathway
        myOApp.setPeer(endPointID, addressToBytes32(address(myOApp)));



        vm.stopBroadcast();
        return (myOApp, helperConfig);
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}

// forge script script/DeployMyOApp.s.sol:DeployMyOApp --rpc-url $AMOY_RPC_URL --private-key $PRIVATE_KEY --broadcast
