pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/token/ERC20/IERC20.sol";

interface IRivera {
    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);
    event TvlCapChange(
        address indexed onwer_,
        uint256 oldTvlCap,
        uint256 newTvlCap
    );
    event UserTvlCapChange(
        address indexed onwer_,
        address indexed user,
        uint256 oldTvlCap,
        uint256 newTvlCap
    );
    event SharePriceChange(uint256 sharePriceX96, uint256 unutilizedAssetBal);
    struct StratCandidate {
        address implementation;
        uint proposedTime;
    }

    function deposit(uint _amount, address _reci) external;

    function balanceOf(address _user) external view returns (uint256);

    function redeem(
        uint _shares,
        address _reciever,
        address _owner
    ) external view returns (uint256);

    function withdraw(
        uint _shares,
        address _reciever,
        address _owner
    ) external returns (uint256);

    function convertToAssets(uint256 _shares) external view returns (uint256);

    function convertToShares(uint256 _shares) external view returns (uint256);
}



