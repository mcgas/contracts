// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

contract HelperConfig is Script {
    LZConfig public activeLZConfig;
    

    struct LZConfig {
        uint32 endPointID;
        address endpointV2;
        address sendUln302;
        address receiveUln302;
        address sendUln301;
        address receiveUln301;
        address lZExecutor;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 80002) {
            activeLZConfig = getAmoyLZConfig();
        } else if (block.chainid == 17000) {
            activeLZConfig = getHoleskyLZConfig();
        } else {
            activeLZConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getAmoyLZConfig() public view returns (LZConfig memory amoyLZConfig) {
        amoyLZConfig = LZConfig({
            endPointID: 40267,
            endpointV2: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            sendUln302: 0x1d186C560281B8F1AF831957ED5047fD3AB902F9,
            receiveUln302: 0x53fd4C4fBBd53F6bC58CaE6704b92dB1f360A648,
            sendUln301: 0xa78A78a13074eD93aD447a26Ec57121f29E8feC2,
            receiveUln301: 0x88B27057A9e00c5F05DDa29241027afF63f9e6e0,
            lZExecutor: 0x4Cf1B3Fa61465c2c907f82fC488B43223BA0CF93,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getHoleskyLZConfig() public view returns (LZConfig memory amoyLZConfig) {
        amoyLZConfig = LZConfig({
            endPointID: 40217,
            endpointV2: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            sendUln302: 0x21F33EcF7F65D61f77e554B4B4380829908cD076,
            receiveUln302: 0xbAe52D605770aD2f0D17533ce56D146c7C964A0d,
            sendUln301: 0xDD066F8c7592bf7235F314028E5e01a66F9835F0,
            receiveUln301: 0x8d00218390E52B30d755882E09B2418eD08dCa7d,
            lZExecutor: 0xBc0C24E6f24eC2F1fd7E859B8322A1277F80aaD5,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public returns (LZConfig memory anvilNetworkConfig) {
        // Check to see if we set an active network config
        if (activeLZConfig.endpointV2 != address(0)) {
            return activeLZConfig;
        }

        // vm.startBroadcast();
        // MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        // ERC20Mock wethMock = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);

        // MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        // ERC20Mock wbtcMock = new ERC20Mock("WBTC", "WBTC", msg.sender, 1000e8);
        // vm.stopBroadcast();

        anvilNetworkConfig = LZConfig({
            endPointID: 31337,
            endpointV2: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            sendUln302: 0x1d186C560281B8F1AF831957ED5047fD3AB902F9,
            receiveUln302: 0x53fd4C4fBBd53F6bC58CaE6704b92dB1f360A648,
            sendUln301: 0xa78A78a13074eD93aD447a26Ec57121f29E8feC2,
            receiveUln301: 0x88B27057A9e00c5F05DDa29241027afF63f9e6e0,
            lZExecutor: 0x4Cf1B3Fa61465c2c907f82fC488B43223BA0CF93,
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}
