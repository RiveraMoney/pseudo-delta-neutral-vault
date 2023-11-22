pragma solidity ^0.8.0;

struct Reward {
    uint256 periodFinish;
    uint256 rewardRate;
    uint256 lastUpdateTime;
    uint256 rewardPerTokenStored;
    uint256 balance;
}
struct Balances {
    uint256 total;
    uint256 unlocked;
    uint256 locked;
    uint256 earned;
}
struct LockedBalance {
    uint256 amount;
    uint256 unlockTime;
}
struct RewardData {
    address token;
    uint256 amount;
}

interface IMultiFeeDistribution {
    event Paused();
    event Unpaused();

    function addReward(address rewardsToken) external;

    function mint(address user, uint256 amount, bool withPenalty) external;

    function getReward() external;

    function withdraw(uint256 amount) external;

    function unlockedBalance(
        address user
    ) external view returns (uint256 amount);

    function earnedBalances(
        address user
    )
        external
        view
        returns (uint256 total, LockedBalance[] memory earningsData);

    function lockedBalances(
        address user
    )
        external
        view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );

    function withdrawableBalance(
        address user
    ) external view returns (uint256 amount, uint256 penaltyAmount);

    function totalBalance(address user) external view returns (uint256 amount);

    function claim(address _user, address[] calldata _tokens) external;

    function claimableReward(
        address _user,
        address[] calldata _tokens
    ) external view returns (uint256[] memory);
}
