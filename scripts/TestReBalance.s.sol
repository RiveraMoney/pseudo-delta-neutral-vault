// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/strategies/common/AbstractStrategy.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/irs/PdnRivera.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";

import "./Weth.sol";

contract TestReBalance is Script {
    address public vault = 0x821F88928C950F638a94b74cD44A1b676D51a310;
    address public strategy = 0xb642f6F85fc68876700FB2699963611632AD8644;
    address public token = 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9;

    function setUp() public {}

    function run() public {
        uint privateKey = 0xfc2f8cc0abd2d9d05229c8942e8a529d1ba9265eb1b4c720c03f7d074615afbb;
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        vm.startBroadcast(privateKey);
        IStrategy(strategy).reBalance();
        vm.stopBroadcast();
    }
}

// forge script scripts/TestReBalance.s.sol:TestReBalance --rpc-url http://127.0.0.1:8545/ --broadcast -vvv --legacy --slow

// forge script scripts/TestReBalance.s.sol:TestReBalance --rpc-url http://34.235.148.86:8545/ --broadcast -vvv --legacy --slow
