// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/strategies/common/AbstractStrategy.sol";
import "../src/vaults/RiveraAutoCompoundingVaultV2Public.sol";
import "../src/strategies/irs/PdnRivera.sol";
import "../src/strategies/common/interfaces/IStrategy.sol";

import "./Weth.sol";

contract cSwap is Script {
    address public token = 0x09Bc4E0D864854c6aFB6eB9A9cdF58aC190D0dF9;
    address public wEth = 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111;
    address public wMnt = 0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8;
    address public midToken = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE;
    address public router = 0x319B69888b0d11cEC22caA5034e25FfFBDc88421; //agni v3
    
    bytes32 public pId =
        0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace; //weth id
    bytes32 public pIB =
        0x4e3037c822d852d79af3ac80e35eb420ee3b870dca49f9344a38ef4773fb0585; //wmnt
    bytes32 public pIusdc =
        0xeaa020c61cc479712813461ce153894a96a6c00b21ed0cfc2798d1f9a9e9c94a; // usdc
        address public pyth = 0xA2aa501b19aff244D90cc15a4Cf739D2725B5729;
    uint24 public fees = 500;


    function setUp() public {}

    function run() public {

        //0xf12Ac6acb0B8542B1c717E520A5B4C085222e4b9

        address gaus = 0xFaBcc4b22fFEa25D01AC23c5d225D7B27CB1B6B8;
        uint privateKey = 0xfc2f8cc0abd2d9d05229c8942e8a529d1ba9265eb1b4c720c03f7d074615afbb;
        address acc = vm.addr(privateKey);
        console.log("Account", acc);

        vm.startBroadcast(privateKey);

        // Weth(wMnt).deposit{value: 3000 * 1e18}();

        // uint256 bW = Weth(wMnt).balanceOf(acc);
        // IERC20(wMnt).approve(router, bW);
        // _swapV3In(wMnt, wEth, 2000e18, fees);

        // uint256 usdcB = IERC20(token).balanceOf(acc);

        // console.log("usdc ", usdcB);
        // IERC20(token).approve(router, usdcB);
        // _swapV3In(token, wEth, usdcB, fees);


     uint256 amountIn = tokenToTokenConversion(wMnt , pIB ,wEth ,pId ,)
     


        console.log("eth", IERC20(wEth).balanceOf(acc));

        vm.stopBroadcast();
    }

    function swapTokens(
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) public {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        IPancakeRouter02(router).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            0x69605b7A74D967a3DA33A20c1b94031BC6cAF27c,
            block.timestamp * 2
        );
    }

    function _swapV3In(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 fee
    ) public returns (uint256 amountOut) {
        amountOut = IV3SwapRouter(router).exactInputSingle(
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

        function tokenToTokenConversion(
        address tokenA,
        bytes32 idA,
        address tokenC,
        bytes32 idB,
        uint amountInA
    ) public view returns (uint) {
        uint256 aDec = IERC20Metadata(tokenA).decimals();
        uint256 bDec = IERC20Metadata(tokenC).decimals();

        uint256 tokenAPrice = uint256(
            int256(IPyth(pyth).getPriceUnsafe(idA).price)
        );

        uint256 tokenCPrice = uint256(
            int256(IPyth(pyth).getPriceUnsafe(idB).price)
        );

        uint256 amountAinUSD = ((10 ** aDec) * (1e8)) / (tokenAPrice); // A in 1 usd

        uint256 amountCinUSD = ((10 ** bDec) * (1e8)) / (tokenCPrice); // C in 1 USD

        uint256 amountCinA = (amountCinUSD * (10 ** aDec)) / amountAinUSD; // amount of C in 1 A token

        return (amountCinA * amountInA) / (10 ** aDec);
    }
}

// forge script scripts/CheckSwaps.s.sol:cSwap --rpc-url http://127.0.0.1:8545/ --broadcast -vvv --legacy --slow