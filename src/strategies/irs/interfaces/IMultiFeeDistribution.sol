pragma solidity ^0.8.0;

interface IMultiFeeDistribution {
    event Paused();
    event Unpaused();

    function addReward(address rewardsToken) external;

    function mint(address user, uint256 amount, bool withPenalty) external;

    function getReward() external;
}
