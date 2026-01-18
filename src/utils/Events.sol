//SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

event Deposit(uint256 amount, uint256 timestamp);
event Withdraw(uint256 amount, uint256 timestamp);
event StrategyChanged(address newStrategy);
event Harvest(uint256 amount);
event VaultChanged(address indexed oldVault, address indexed newVault, uint256 timestamp);
event EmergencyWithdraw(uint256 amount, uint256 timestamp);
