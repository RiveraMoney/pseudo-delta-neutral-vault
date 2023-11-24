// pragma solidity ^0.8.0;

// import "@openzeppelin/token/ERC20/IERC20.sol";
// import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
// import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/access/Ownable.sol";
// import "@openzeppelin/security/Pausable.sol";
// import "@openzeppelin/security/ReentrancyGuard.sol";

// import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";
// import "./OracleInterface/IPyth.sol";
// import "./interfaces/DataTypes.sol";
// import "./interfaces/IV3SwapRouter.sol";

// import "./interfaces/ILendingPool.sol";
// import "./interfaces/IRivera.sol";
// import "./interfaces/ILendingPoolAddressesProvider.sol";
// import "./interfaces/IMultiFeeDistribution.sol";
// import "../../libs/LiquiMaths.sol";

// import "../common/AbstractStrategy.sol";
// import "../utils/StringUtils.sol";

// import "./PdnRivera.sol";

// contract PdnRiveraVolatileBase is PdnRivera {
    
//     address public baseTokenVolatile; // address of other token if both token in pair are volatile
//     bytes32 public pIdB;           // pyth price feed id for this token
//     address public stableToken; // stable token address for price calculations from oracle usually usdc

//     constructor(
//         CommonAddresses memory _commonAddresses,
//         PdnParams memory _PdnParams,
//         PdnFeesParams memory _PdnFeesParams,
//         PdnHarvestParams memory _PdnHarvestParams,
//         address _baseTokenVolatile,
//         bytes32 _pIdB,
//         uint24 _poolFees,
//         uint256 _oracleDeci
//     )
//         PdnRivera(
//             _commonAddresses,
//             _PdnParams,
//             _PdnFeesParams,
//             _PdnHarvestParams,
//             _poolFees,
//             _oracleDeci
//         )
//     {
//         baseToken = _baseTokenVolatile;
//         pIdB = _pIdB;
//         stableToken = _PdnParams.baseToken;
//     }


// //StableToTokenConversion
//      function _deposit() internal override{
//          uint256 dBal = IERC20(baseToken).balanceOf(address(this));
        
//         // uint256 balStable = tokenToStableConversion(dBal , IERC20Metadata(baseToken).decimals() ,IERC20Metadata(stableToken).decimals() ,pIdB);
        
//          uint256 lendAmount = LiquiMaths.calculateLend(
//             ltv,
//             dBal,
//             uint256(IERC20Metadata(baseToken).decimals())
//         );

//         depositAave(lendAmount);

//         uint256 borrowTokenInBase = LiquiMaths.calculateBorrow(
//             ltv,
//             dBal,
//             uint256(IERC20Metadata(baseToken).decimals())
//         );

//         uint256 borrowInStable = tokenToStableConversion(borrowTokenInBase , IERC20Metadata(baseToken).decimals() ,IERC20Metadata(stableToken).decimals() ,pIdB);
         
//         uint256 borrowInTokenB = StableToTokenConversion(borrowInStable , IERC20Metadata(tokenB).decimals(),IERC20Metadata(stableToken).decimals(), pId);

//        borrowAave(borrowInTokenB);

//         uint256 etV = IERC20(tokenB).balanceOf(address(this));
//         _swapV3In(tokenB, baseToken, etV, poolFees);
//         addLiquidity();

//      }

//      function totalDebt() public view override returns (uint256){
//         uint256 debt = IERC20(debtToken).balanceOf(address(this));
//         uint256 debtInStable = tokenToStableConversion(debt , IERC20Metadata(tokenB).decimals(),IERC20Metadata(stableToken).decimals(),pIdB);
//         uint256 debtInBase = StableToTokenConversion(debtInStable ,IERC20Metadata(baseToken).decimals(),IERC20Metadata(stableToken).decimals(),pId);
//         return debtInBase;
//      }
// }
