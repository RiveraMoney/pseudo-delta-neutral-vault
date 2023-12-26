// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/strategies/common/AbstractStrategy.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/irs/PdnRivera.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";

import "./Weth.sol";
    
contract BuyTokens is Script {
    address public token = 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9;
    address public wEth = 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111;
    address public wMnt = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8;
    address public midToken = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE;
    address public router = 0x319B69888b0d11cEC22caA5034e25FfFBDc88421;
    address public routerF = 0x5989FB161568b9F133eDf5Cf6787f5597762797F;
    uint24 public fees = 500;

    // path[0] = wEth;
    // path[1] = token;

    function setUp() public {}

    function run() public {
        address gaus = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8;
        uint privateKey = 0xfc2f8cc0abd2d9d05229c8942e8a529d1ba9265eb1b4c720c03f7d074615afbb;
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        vm.startBroadcast(privateKey);

        Weth(wMnt).deposit{value: 4000 * 1e18}();

        uint256 bW = Weth(wMnt).balanceOf(acc);
        IERC20(wMnt).approve(router, bW);
        _swapV3In(wMnt, token, bW, fees);

        console.log("USDC:-" , IERC20(token).balanceOf(acc));

        Weth(wMnt).deposit{value: 4000 * 1e18}();

         bW = Weth(wMnt).balanceOf(acc);
        IERC20(wMnt).approve(router, bW);
        _swapV3In(wMnt, wEth, bW, fees);

        console.log("wEth:-" , IERC20(wEth).balanceOf(acc));

        // uint256 usdcB = IERC20(token).balanceOf(acc);

        // console.log("usdc ", usdcB);
        // IERC20(token).approve(router, usdcB);
        // _swapV3In(token, wEth, usdcB, fees);

        // console.log("eth", IERC20(wEth).balanceOf(acc));

        vm.stopBroadcast();
    }

    // function swapTokens(
    //     address tokenA,
    //     address tokenB,
    //     uint256 amountIn
    // ) public {
    //     address[] memory path = new address[](2);
    //     path[0] = tokenA;
    //     path[1] = tokenB;

    //     IPancakeRouter02(router).swapExactTokensForTokens(
    //         amountIn,
    //         0,
    //         path,
    //         0x69605b7A74D967a3DA33A20c1b94031BC6cAF27c,
    //         block.timestamp * 2
    //     );
    // }

    function _swapV3In(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 fee
    ) public returns (uint256 amountOut) {
        amountOut = IV3SwapRouter(routerF).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                0x69605b7A74D967a3DA33A20c1b94031BC6cAF27c,
                block.timestamp * 2,
                amountIn,
                0,
                0
            )
        );
    }
}

// forge script scripts/BuyTokens.s.sol:BuyTokens --rpc-url http://127.0.0.1:8545/ --broadcast -vvv --legacy --slow

// forge script scripts/BuyTokens.s.sol:BuyTokens --rpc-url https://node.rivera.money/  --broadcast -vvv --legacy --slow