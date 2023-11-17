// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/strategies/irs/CommonStrat.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/irs/LendleRivera.sol";
import "../src/strategies/irs/interfaces/ILendleRivera.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";

import "./Weth.sol";
import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";

contract CheckDeposit is Script {
    address public vault = 0x33e47Fe37FeF6AB1d83e54AAD6c8D01C048171E1;
    address public strategy = 0x8a1b62c438B7b1d73A7a323C6b685fEc021610aC;
    address public token = 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9;

    function setUp() public {}

    function run() public {
        uint privateKey = 0xfc2f8cc0abd2d9d05229c8942e8a529d1ba9265eb1b4c720c03f7d074615afbb;
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        uint256 dpDai = 10 * (10 ** 6);

        vm.startBroadcast(privateKey);

        IERC20(token).approve(vault, dpDai);

        RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, acc);

        console.log(RiveraAutoCompoundingVaultV2Public(vault).totalAssets());
        console.log(RiveraAutoCompoundingVaultV2Public(vault).balanceOf(acc));
        console.log(IERC20(token).balanceOf(acc));
        vm.stopBroadcast();
    }
}

// forge script scripts/CheckDeposit.s.sol:CheckDeposit --rpc-url http://127.0.0.1:8545/ --broadcast -vvv --legacy --slow
