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

//Main variables of Contract
struct PdnParams {
    address baseToken;
    address tokenB;
    address lendingPool;
    address riveraVault;
    address pyth;
    bytes32 pId;
    uint256 ltv;
}

//Variables for Fees
struct PdnFeesParams {
    address protocol;
    address partner;
    uint256 protocolFee;
    uint256 partnerFee;
    uint256 fundManagerFee;
    uint256 feeDecimals;
    uint256 withdrawFee;
    uint256 withdrawFeeDecimals;
}

//Protocol dependent parameters for harvest function
struct PdnHarvestParams {
    address reward;
    address claimC;
    address multiFee;
    address routerH;
}

contract PdnRivera is AbstractStrategy, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public baseToken;
    address public tokenB; //token we are going to borrow
    address public midToken; //midtoken incase there is slippage issue for a pair
    address public debtToken;
    address public aToken;
    address public reward; // token we get for depositing tokens
    uint256 public oracleDeci; // decimals of oracle price
    bytes32 public pId; // id of a token to get its price from oracle

    address public lendingPool;
    address public riveraVault;
    address public pyth; //oracle contract address to get price
    address public claimC; // contract to collect reward tokens
    address public multiFee; // contract to withdraw reward tokens
    address public routerH; //secondary router incase not enough liquidity in v3 pools
    uint24 public poolFees; //v3 pool fees for v3 swap

    uint256 public ltv;
    address public protocol;
    address public partner;
    uint256 public protocolFee;
    uint256 public partnerFee;
    uint256 public fundManagerFee;
    uint256 public feeDecimals;
    uint256 public withdrawFee;
    uint256 public withdrawFeeDecimals;

    /*@dev
following is an array of tokens to collect deposit reward from protocol
will change for different protocols
  */
    address[] public forReward = [
        0xF36AFb467D1f05541d998BBBcd5F7167D67bd8fC,
        0x334a542b51212b8Bcd6F96EfD718D55A9b7D1c35,
        0xE71cbaaa6B093FcE66211E6f218780685077D8B5,
        0xaC3c14071c80819113DF501E1AB767be910d5e5a,
        0x44CCCBbD7A5A9e2202076ea80C185DA0058f1715,
        0x42f9F9202D5F4412148662Cf3bC68D704c8E354f,
        0x787Cb0D29194f0fAcA73884C383CF4d2501bb874,
        0x5DF9a4BE4F9D717b2bFEce9eC350DcF4cbCb91d8,
        0x683696523512636B46A826A7e3D1B0658E8e2e1c,
        0x18d3E4F9951fedcdDD806538857eBED2F5F423B7
    ];

    constructor(
        CommonAddresses memory _commonAddresses,
        PdnParams memory _PdnParams,
        PdnFeesParams memory _PdnFeesParams,
        PdnHarvestParams memory _PdnHarvestParams,
        address _midToken,
        uint24 _poolFees,
        uint256 _oracleDeci
    ) AbstractStrategy(_commonAddresses) {
        baseToken = _PdnParams.baseToken;
        tokenB = _PdnParams.tokenB;
        lendingPool = _PdnParams.lendingPool;
        riveraVault = _PdnParams.riveraVault;
        pyth = _PdnParams.pyth;
        pId = _PdnParams.pId;
        ltv = _PdnParams.ltv;

        partner = _PdnFeesParams.partner;
        protocol = _PdnFeesParams.protocol;
        protocolFee = _PdnFeesParams.protocolFee;
        partnerFee = _PdnFeesParams.partnerFee;
        fundManagerFee = _PdnFeesParams.fundManagerFee;
        feeDecimals = _PdnFeesParams.feeDecimals;
        withdrawFee = _PdnFeesParams.withdrawFee;
        withdrawFeeDecimals = _PdnFeesParams.withdrawFeeDecimals;

        reward = _PdnHarvestParams.reward;
        claimC = _PdnHarvestParams.claimC;
        multiFee = _PdnHarvestParams.multiFee;
        routerH = _PdnHarvestParams.routerH;

        midToken = _midToken;
        poolFees = _poolFees;
        oracleDeci = _oracleDeci;

        /* @dev
    Fetching both aToken address and debt token address from protocol
    */
        DataTypes.ReserveData memory w = ILendingPool(lendingPool)
            .getReserveData(tokenB);
        DataTypes.ReserveData memory t = ILendingPool(lendingPool)
            .getReserveData(baseToken);
        aToken = t.aTokenAddress;
        debtToken = w.variableDebtTokenAddress;

        _giveAllowances();
    }

    function deposit() public whenNotPaused nonReentrant {
        onlyVault();
        _deposit();
    }

    /* @dev
     puts the funds to work
     */
    function _deposit() internal {
        uint256 tBal = IERC20(baseToken).balanceOf(address(this));

        /* @dev
     calculating the deposit amount from an external library  
     */
        uint256 lendAmount = LiquiMaths.calculateLend(
            ltv,
            tBal,
            uint256(IERC20Metadata(baseToken).decimals())
        );

        // deposit amount in protocol
        depositAave(lendAmount);

        /* @dev
     calculating the deposit amount from an external library  
     */

        uint256 borrowTokenB = LiquiMaths.calculateBorrow(
            ltv,
            tBal,
            uint256(IERC20Metadata(baseToken).decimals())
        );

        //converting amount in stable token to tokenb
        uint256 amounTokenB = StableToTokenConversion(borrowTokenB);

        //borrowing above calculated amount from protocol
        borrowAave(amounTokenB);
        uint256 etV = IERC20(tokenB).balanceOf(address(this));
        _swapV3In(tokenB, baseToken, etV, poolFees);
        addLiquidity();
    }

    function depositAave(uint256 _supply) internal {
        ILendingPool(lendingPool).deposit(baseToken, _supply, address(this), 0);
    }

    function borrowAave(uint256 _borrowAmount) internal {
        ILendingPool(lendingPool).borrow(
            tokenB,
            _borrowAmount,
            2,
            0,
            address(this)
        );
    }

    //Deposit the tokens in rivera vault
    function addLiquidity() internal {
        uint256 tBal = IERC20(baseToken).balanceOf(address(this));
        IRivera(riveraVault).deposit(tBal, address(this));
    }

    function _swapV3In(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 fee
    ) internal returns (uint256 amountOut) {
        amountOut = IV3SwapRouter(router).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams(
                tokenIn,
                tokenOut,
                fee,
                address(this),
                block.timestamp * 2,
                amountIn,
                0,
                0
            )
        );
    }

    function _swapV2(address tokenA, address tokenc, uint256 _amount) internal {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenc;

        IPancakeRouter02(routerH).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp * 2
        );
    }

    function withdraw(uint256 _amount) public nonReentrant {
        onlyVault();

        closeAll(); // close all positions

        //transfer withdraw fees to strategy protocol
        uint256 wFee = (_amount * withdrawFee) / withdrawFeeDecimals;
        IERC20(baseToken).transfer(protocol, wFee);
        uint256 toTrans = _amount - wFee;

        //calculation for withdraw amount
        uint256 crB = IERC20(baseToken).balanceOf(address(this));
        if (crB > toTrans) {
            IERC20(baseToken).transfer(vault, toTrans);
            _deposit();
        } else {
            IERC20(baseToken).transfer(vault, crB);
        }
    }

    //repay the debt of lending protocol
    function repayLoan(uint256 _amount) internal {
        ILendingPool(lendingPool).repay(tokenB, _amount, 2, address(this));
    }

    // withdraw deposited fund from the lending protocol
    function withdrawAave(uint256 _amount) internal {
        ILendingPool(lendingPool).withdraw(baseToken, _amount, address(this));
    }

    // function to convert an amount from stable currency to non-stable token
    function StableToTokenConversion(
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 tokenPrice = uint256(
            int256(IPyth(pyth).getPriceUnsafe(pId).price)
        );

        uint256 deciL = IERC20Metadata(tokenB).decimals();
        uint256 weiU = ((10 ** deciL) * (10 ** oracleDeci)) / (tokenPrice);
        uint256 deci = IERC20Metadata(baseToken).decimals();
        uint256 amountInToken = (weiU * _amount) / 10 ** deci;

        return amountInToken;
    }

    // function to convert an amount from not stable token to stable currency
    function tokenToStableConversion(
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 tokenPrice = uint256(
            int256(IPyth(pyth).getPriceUnsafe(pId).price)
        );

        uint256 deciL = IERC20Metadata(tokenB).decimals();

        uint256 weiU = (10 ** deciL * (10 ** oracleDeci)) / (tokenPrice);

        uint256 deci = IERC20Metadata(baseToken).decimals();

        uint256 amountInStable = (_amount * 10 ** deci) / weiU;
        return amountInStable;
    }

    // rebalance the whole positions
    function reBalance() public {
        onlyManager();
        harvest();
        closeAll();
        _deposit();
    }

    // retire the strategy and transfer the tokens to vault
    function retireStrat() external {
        onlyVault();
        closeAll();
        uint256 totalBal = IERC20(baseToken).balanceOf(address(this));
        IERC20(baseToken).transfer(vault, totalBal);
    }

    // close all positions from rivera and lending protocol
    function closeAll() internal {
        uint256 rBal = IRivera(riveraVault).balanceOf(address(this));
        uint256 balA = IRivera(riveraVault).convertToAssets(rBal);
        IRivera(riveraVault).withdraw(balA, address(this), address(this));

        uint256 balT = IERC20(baseToken).balanceOf(address(this));
        _swapV3In(baseToken, tokenB, balT, poolFees);

        uint256 debtNow = IERC20(debtToken).balanceOf(address(this));
        repayLoan(debtNow);

        uint256 inAmount = IERC20(aToken).balanceOf(address(this));
        withdrawAave(inAmount);
        balT = IERC20(tokenB).balanceOf(address(this));
        _swapV3In(tokenB, baseToken, balT, poolFees);
    }

    // collect and redeposit the reward tokens
    function harvest() public whenNotPaused {
        IMultiFeeDistribution(claimC).claim(address(this), forReward);
        (uint256 amount, uint256 penalty) = IMultiFeeDistribution(multiFee)
            .withdrawableBalance(address(this));
        IMultiFeeDistribution(multiFee).withdraw((amount * 99) / 100);
        uint256 lBal = IERC20(reward).balanceOf(address(this));
        _swapV2(reward, midToken, lBal);
        uint256 mBal = IERC20(midToken).balanceOf(address(this));
        _swapV3In(midToken, baseToken, mBal, poolFees);
        _chargeFees(baseToken);
        _deposit();
    }

    // total balance of strategy
    function balanceOf() public view returns (uint256) {
        return balanceRivera() + balanceDeposit() - totalDebt();
    }

    // balance deposited in rivera vault
    function balanceRivera() public view returns (uint256) {
        uint256 balS = IRivera(riveraVault).balanceOf(address(this));
        return IRivera(riveraVault).convertToAssets(balS);
    }

    // balance deposited in lending protocol
    function balanceDeposit() public view returns (uint256) {
        return IERC20(aToken).balanceOf(address(this));
    }

    // current debt
    function totalDebt() public view returns (uint256) {
        uint256 debt = IERC20(debtToken).balanceOf(address(this));
        return tokenToStableConversion(debt);
    }

    function inCaseTokensGetStuck(address _token) external {
        onlyManager();
        uint256 amount = IERC20(_token).balanceOf(address(this)); //Just finding the balance of this vault contract address in the the passed baseToken and transfers
        IERC20(_token).transfer(msg.sender, amount);
    }

    function _chargeFees(address _token) internal {
        uint256 tokenBal = IERC20(_token).balanceOf(address(this));

        uint256 protocolFeeAmount = (tokenBal * protocolFee) / feeDecimals;
        IERC20(_token).safeTransfer(manager, protocolFeeAmount);

        uint256 fundManagerFeeAmount = (tokenBal * fundManagerFee) /
            feeDecimals;
        IERC20(_token).safeTransfer(owner(), fundManagerFeeAmount);

        uint256 partnerFeeAmount = (tokenBal * partnerFee) / feeDecimals;
        IERC20(_token).safeTransfer(partner, partnerFeeAmount);
    }

    function panic() public {
        onlyManager();
        closeAll();
        pause();
    }

    function pause() public {
        onlyManager();
        _pause();

        _removeAllowances();
    }

    function unpause() external {
        onlyManager();
        _unpause();

        _giveAllowances();

        _deposit();
    }

    function _giveAllowances() internal virtual {
        IERC20(baseToken).approve(router, type(uint256).max);
        IERC20(baseToken).approve(routerH, type(uint256).max);
        IERC20(baseToken).approve(lendingPool, type(uint256).max);
        IERC20(baseToken).approve(riveraVault, type(uint256).max);

        IERC20(tokenB).approve(router, type(uint256).max);
        IERC20(tokenB).approve(routerH, type(uint256).max);
        IERC20(tokenB).approve(lendingPool, type(uint256).max);
        IERC20(tokenB).approve(riveraVault, type(uint256).max);

        IERC20(reward).approve(router, type(uint256).max);
        IERC20(reward).approve(routerH, type(uint256).max);
        IERC20(reward).approve(lendingPool, type(uint256).max);
        IERC20(reward).approve(riveraVault, type(uint256).max);

        IERC20(midToken).approve(router, type(uint256).max);
        IERC20(midToken).approve(routerH, type(uint256).max);
        IERC20(midToken).approve(lendingPool, type(uint256).max);
        IERC20(midToken).approve(riveraVault, type(uint256).max);
    }

    function _removeAllowances() internal virtual {
        IERC20(baseToken).safeApprove(router, 0);
        IERC20(baseToken).safeApprove(lendingPool, 0);
        IERC20(baseToken).safeApprove(riveraVault, 0);

        IERC20(tokenB).safeApprove(router, 0);
        IERC20(tokenB).safeApprove(lendingPool, 0);
        IERC20(tokenB).safeApprove(riveraVault, 0);
    }
}
