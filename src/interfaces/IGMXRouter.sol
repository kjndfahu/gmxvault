//SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

interface IGMXRouter {
    function depositToPool(address token, uint256 amount) external;
    function withdrawFromPool(address token, uint256 amount) external;
    function getPoolBalance(address token) external view returns (uint256);
}
