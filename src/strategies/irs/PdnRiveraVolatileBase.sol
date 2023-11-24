pragma solidity ^0.8.0;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/security/Pausable.sol";
import "@openzeppelin/security/ReentrancyGuard.sol";

import "@pancakeswap-v2-exchange-protocol/interfaces/IPancakeRouter02.sol";
import "./OracleInterface/IPyth.sol";
import "./interfaces/DataTypes.sol";
import "./interfaces/IV3SwapRouter.sol";

import "./interfaces/ILendingPool.sol";
import "./interfaces/IRivera.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/IMultiFeeDistribution.sol";
import "../../libs/LiquiMaths.sol";

import "../common/AbstractStrategy.sol";
import "../utils/StringUtils.sol";

import "./PdnRivera.sol";

contract PdnRiveraVolatileBase is PdnRivera{

    constructor(CommonAddresses memory _commonAddresses,
        PdnParams memory _PdnParams,
        PdnFeesParams memory _PdnFeesParams,
        PdnHarvestParams memory _PdnHarvestParams,
        address _midToken,
        uint24 _poolFees,
        uint256 _oracleDeci) PdnRivera( _commonAddresses,
      _PdnParams,
    _PdnFeesParams,
        _PdnHarvestParams,
   _midToken,
     _poolFees,
       _oracleDeci){

       }
}