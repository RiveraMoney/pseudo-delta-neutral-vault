// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";

import "./Weth.sol";
import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";

contract CheckWithdraw is Script {
    address public vault = 0xf5eB7A02d1B8Dc14D5419Ee9F3f4DeE342960e08;
    // address public strategy = 0x8a1b62c438B7b1d73A7a323C6b685fEc021610aC;
    address public token = 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9;

    function setUp() public {}

    function run() public {
        uint privateKey = 0xfc2f8cc0abd2d9d05229c8942e8a529d1ba9265eb1b4c720c03f7d074615afbb;
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        vm.startBroadcast(privateKey);
        uint256 withd = 1e6;
        console.log("before");
        console.log(RiveraAutoCompoundingVaultV2Public(vault).balanceOf(acc));

        RiveraAutoCompoundingVaultV2Public(vault).withdraw(withd, acc, acc);

        console.log("after");
        console.log(RiveraAutoCompoundingVaultV2Public(vault).balanceOf(acc));
        console.log(RiveraAutoCompoundingVaultV2Public(vault).totalAssets());
    }
}

// forge script scripts/CheckWithdraw.s.sol:CheckWithdraw --rpc-url https://node.rivera.money/ --broadcast -vvv --legacy --slow
