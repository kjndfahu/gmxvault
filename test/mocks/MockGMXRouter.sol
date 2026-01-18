//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockGMXRouter {
    mapping(address => uint256) public poolBalance;

    function depositToPool(address _token, uint256 _amount) public {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        poolBalance[_token] += _amount;
    }

    function withdrawFromPool(address _token, uint256 _amount) public {
        poolBalance[_token] -= _amount;
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function getPoolBalance(address _token) external view returns (uint256) {
        return poolBalance[_token];
    }
}
