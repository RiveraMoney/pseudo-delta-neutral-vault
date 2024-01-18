// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RiveraAutoCompoundingVaultV2Public.sol";
import "../strategies/common/interfaces/IStrategy.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";


contract WrapperVault {
    address public vault;
    address public token;
    address public strategy;

    constructor(address _vault,address _token,address _strategy){
        vault = _vault;
        token = _token;
        strategy = _strategy;
    }

    function deposit(uint256 _amount , address _reciever ,bytes []memory pythData) public {
      IERC20(token).transferFrom(msg.sender,address(this),_amount);
      IERC20(token).approve(vault,_amount);
      IStrategy(strategy).setData(pythData);
      RiveraAutoCompoundingVaultV2Public(vault).deposit(_amount,address(this));
      uint256 shares = IERC20(vault).balanceOf(address(this));
      IERC20(vault).transfer(_reciever,shares);
    }

    function withdraw(uint256 _amount , address _reciever ,bytes []memory pythData) public {
        IERC20(vault).transferFrom(msg.sender,address(this),_amount);
        IStrategy(strategy).setData(pythData);
        RiveraAutoCompoundingVaultV2Public(vault).withdraw(_amount,address(this),address(this));
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender,bal);
    }
}