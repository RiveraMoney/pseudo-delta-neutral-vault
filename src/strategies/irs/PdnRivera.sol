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


import "./interfaces/IRivera.sol";
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
    bytes32 pIdB;
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
    address midToken;
    address claimC;
    address multiFee;
    address routerV2;
}

contract PdnRivera is
    AbstractStrategy,
    ReentrancyGuard //PdnRiveraVolatileBase
{
    using SafeERC20 for IERC20;

    address public baseToken;
    address public tokenB; //token we are going to borrow
    address public midToken; //midtoken incase there is slippage issue for a pair
    address public debtToken;
    address public aToken;
    address public reward; // token we get for depositing tokens
    uint256 public oracleDeci; // decimals of oracle price
    bytes32 public pId; // id of a token to get its price from oracle
    bytes32 public pIdB; // id of a tokenB to get its price from oracle

    address public lendingPool;
    address public riveraVault;
    address public pyth; //oracle contract address to get price
    address public claimC; // contract to collect reward tokens
    address public multiFee; // contract to withdraw reward tokens
    address public routerV2; //secondary router incase not enough liquidity in v3 pools
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

    event StratHarvest(address indexed harvester, uint256 tvl);

    event Deposit(uint256 tvl, uint256 amount);
    event Withdraw(uint256 tvl, uint256 amount);

    /*@dev
following is an array of tokens to collect deposit reward from protocol
will change for different protocols
  */


    constructor(
        CommonAddresses memory _commonAddresses,
        PdnParams memory _PdnParams,
        PdnFeesParams memory _PdnFeesParams,
        PdnHarvestParams memory _PdnHarvestParams,
        uint24 _poolFees,
        uint256 _oracleDeci
    ) AbstractStrategy(_commonAddresses) {
        baseToken = _PdnParams.baseToken;
        tokenB = _PdnParams.tokenB;
        lendingPool = _PdnParams.lendingPool;
        riveraVault = _PdnParams.riveraVault;
        pyth = _PdnParams.pyth;
        pId = _PdnParams.pId;
        pIdB = _PdnParams.pIdB;
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
        routerV2 = _PdnHarvestParams.routerV2;
        midToken = _PdnHarvestParams.midToken;

        DataTypes.ReserveData memory w = ILendingPool(lendingPool)
            .getReserveData(tokenB);
        DataTypes.ReserveData memory t = ILendingPool(lendingPool)
            .getReserveData(baseToken);
        aToken = t.aTokenAddress;
        debtToken = w.variableDebtTokenAddress;

        poolFees = _poolFees;
        oracleDeci = _oracleDeci;

        _giveAllowances();
    }

    function deposit() public whenNotPaused nonReentrant {
        onlyVault();
        _deposit();
    }

    /* @dev
     puts the funds to work
     */
    function _deposit() internal virtual {
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
        uint256 amounTokenB = tokenToTokenConversion(
            baseToken,
            pId,
            tokenB,
            pIdB,
            borrowTokenB
        );

        //borrowing above calculated amount from protocol
        borrowAave(amounTokenB);
        uint256 etV = IERC20(tokenB).balanceOf(address(this));
        _swapV3In(tokenB, baseToken, etV, poolFees);
        addLiquidity();

        emit Deposit(balanceOf(), tBal);
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

        IPancakeRouter02(routerV2).swapExactTokensForTokens(
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

        emit Withdraw(balanceOf(), _amount);
    }

    //repay the debt of lending protocol
    function repayLoan(uint256 _amount) internal {
        ILendingPool(lendingPool).repay(tokenB, _amount, 2, address(this));
    }

    // withdraw deposited fund from the lending protocol
    function withdrawAave(uint256 _amount) internal {
        ILendingPool(lendingPool).withdraw(baseToken, _amount, address(this));
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

        uint256 amountAinUSD = ((10 ** aDec) * (10 ** oracleDeci)) /
            (tokenAPrice); // A in 1 usd

        uint256 amountCinUSD = ((10 ** bDec) * (10 ** oracleDeci)) /
            (tokenCPrice); // C in 1 USD

        uint256 amountCinA = (amountCinUSD * (10 ** aDec)) / amountAinUSD; // amount of C in 1 A token

        return (amountCinA * amountInA) / (10 ** aDec);
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

        emit StratHarvest(msg.sender, balanceOf());
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
    function totalDebt() public view virtual returns (uint256) {
        uint256 debt = IERC20(debtToken).balanceOf(address(this));
        return tokenToTokenConversion(tokenB, pIdB, baseToken, pId, debt);
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
        IERC20(baseToken).approve(routerV2, type(uint256).max);
        IERC20(baseToken).approve(lendingPool, type(uint256).max);
        IERC20(baseToken).approve(riveraVault, type(uint256).max);

        IERC20(tokenB).approve(router, type(uint256).max);
        IERC20(tokenB).approve(routerV2, type(uint256).max);
        IERC20(tokenB).approve(lendingPool, type(uint256).max);
        IERC20(tokenB).approve(riveraVault, type(uint256).max);

        IERC20(reward).approve(router, type(uint256).max);
        IERC20(reward).approve(routerV2, type(uint256).max);
        IERC20(reward).approve(lendingPool, type(uint256).max);
        IERC20(reward).approve(riveraVault, type(uint256).max);

        IERC20(midToken).approve(router, type(uint256).max);
        IERC20(midToken).approve(routerV2, type(uint256).max);
        IERC20(midToken).approve(lendingPool, type(uint256).max);
        IERC20(midToken).approve(riveraVault, type(uint256).max);
    }

    function _removeAllowances() internal virtual {
        IERC20(baseToken).safeApprove(router, 0);
        IERC20(baseToken).safeApprove(routerV2, 0);
        IERC20(baseToken).safeApprove(lendingPool, 0);
        IERC20(baseToken).safeApprove(riveraVault, 0);

        IERC20(tokenB).safeApprove(router, 0);
        IERC20(tokenB).safeApprove(routerV2, 0);
        IERC20(tokenB).safeApprove(lendingPool, 0);
        IERC20(tokenB).safeApprove(riveraVault, 0);

        IERC20(reward).safeApprove(router, 0);
        IERC20(reward).safeApprove(routerV2, 0);
        IERC20(reward).safeApprove(lendingPool, 0);
        IERC20(reward).safeApprove(riveraVault, 0);

        IERC20(midToken).safeApprove(router, 0);
        IERC20(midToken).safeApprove(routerV2, 0);
        IERC20(midToken).safeApprove(lendingPool, 0);
        IERC20(midToken).safeApprove(riveraVault, 0);
    }
}
