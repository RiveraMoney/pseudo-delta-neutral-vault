pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/token/ERC20/IERC20.sol";

interface ICommonStrat {
    function vault() external view returns (address);

    function asset() external view returns (address);

    function balanceOfAsset() external view returns (uint256);

    function balanceOf() external view returns (uint256);

    function interestDecimals() external view returns (uint256);

    function interest() external view returns (uint256);
}
