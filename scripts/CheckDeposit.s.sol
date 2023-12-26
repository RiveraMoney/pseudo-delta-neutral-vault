// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/strategies/common/AbstractStrategy.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/irs/PdnRivera.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";

import "./Weth.sol";
import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";

contract CheckDeposit is Script {
    address public vault = 0xb642f6F85fc68876700FB2699963611632AD8644;
    address public strategy = 0xf5eB7A02d1B8Dc14D5419Ee9F3f4DeE342960e08;
    address public token = 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111;

    function setUp() public {}

    function run() public {
        uint privateKey = 0xfc2f8cc0abd2d9d05229c8942e8a529d1ba9265eb1b4c720c03f7d074615afbb;
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        uint256 dpDai = 5e16;

        vm.startBroadcast(privateKey);

        IERC20(token).approve(vault, dpDai);

        RiveraAutoCompoundingVaultV2Public(vault).deposit(dpDai, acc);

        console.log(RiveraAutoCompoundingVaultV2Public(vault).totalAssets());
        console.log(RiveraAutoCompoundingVaultV2Public(vault).balanceOf(acc));
        console.log(IERC20(token).balanceOf(acc));
        vm.stopBroadcast();
    }
}

// forge script scripts/CheckDeposit.s.sol:CheckDeposit --rpc-url https://node.rivera.money/ --broadcast -vvv --legacy --slow
