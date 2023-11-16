pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/token/ERC20/IERC20.sol";

interface IStrategy {
    //Events
    event StratHarvest(
        address indexed harvester,
        uint256 stakeHarvested,
        uint256 tvl
    );
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);

    struct ComonStratData {
        uint256 stakedInNative;
        uint256 returnAmountNative;
    }

    function vault() external view returns (address);

    function chef() external view returns (address);

    function stake() external view returns (address);

    function reward() external view returns (IERC20);

    function lpToken0() external view returns (IERC20);

    function lpToken1() external view returns (IERC20);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceDeposit() external view returns (uint256);

    function balanceRivera() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function harvest() external;

    function managerHarvest() external;

    function reBalance() external;

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function router() external view returns (address);

    function poolId() external view returns (uint256);

    function rewardToLp0Route(uint256) external view returns (address);

    function rewardToLp1Route(uint256) external view returns (address);

    function rewardsAvailable() external view returns (uint256);

    function tokenToEthConversion(
        uint256 _amount
    ) external view returns (uint256);

    function ethToTokenConversion(
        uint256 _amount
    ) external view returns (uint256);

    function owner() external view returns (address);

    function manager() external view returns (address);

    function assetStrategyMap(
        address
    ) external view returns (ComonStratData memory);

    function epochRunning() external view returns (bool);

    function closeAll() external;
}
