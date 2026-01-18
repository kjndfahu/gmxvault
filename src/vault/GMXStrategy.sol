// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IGMXRouter.sol";
import "../utils/Errors.sol";
import "../utils/Events.sol";

/// @title GMX Strategy
/// @notice Handles deposits and withdrawals of ERC20 assets into the GMX protocol
/// @dev Only callable by the assigned vault, with emergency withdrawal available to owner
contract GMXStrategy is IStrategy, Ownable {
    /// @notice ERC20 token managed by the strategy
    IERC20 public immutable asset;

    /// @notice GMX Router interface for interacting with GMX protocol
    IGMXRouter public immutable gmxRouter;

    /// @notice Vault contract that is authorized to call deposits/withdrawals
    address public vault;

    /// @notice Initializes the strategy
    /// @param _asset Address of the ERC20 asset token
    /// @param _gmxRouter Address of the GMX Router
    /// @param _vault Address of the initial vault
    constructor(address _asset, address _gmxRouter, address _vault) Ownable(msg.sender) {
        if (_asset == address(0)) revert ZeroAddress();
        if (_gmxRouter == address(0)) revert ZeroAddress();

        asset = IERC20(_asset);
        gmxRouter = IGMXRouter(_gmxRouter);
        vault = _vault;

        IERC20(_asset).approve(_gmxRouter, type(uint256).max);
    }

    /// @notice Modifier to restrict function calls to the vault only
    modifier onlyVault() {
        if (vault == address(0)) revert VaultNotSet();
        if (msg.sender != vault) revert Unauthorized();
        _;
    }

    /// @notice Deposit assets from the vault into the GMX pool
    /// @param _amount Amount of asset to deposit
    function deposit(uint256 _amount) public onlyVault {
        if (_amount == 0) revert ZeroAmount();

        asset.transferFrom(vault, address(this), _amount);
        gmxRouter.depositToPool(address(asset), _amount);

        emit Deposit(_amount, block.timestamp);
    }

    /// @notice Withdraw assets from the GMX pool back to the vault
    /// @param _amount Amount of asset to withdraw
    function withdraw(uint256 _amount) public onlyVault {
        if (_amount == 0) revert ZeroAmount();

        gmxRouter.withdrawFromPool(address(asset), _amount);

        if (asset.balanceOf(address(this)) < _amount) revert InsufficientBalance();

        asset.transfer(vault, _amount);

        emit Withdraw(_amount, block.timestamp);
    }

    /// @notice Returns total assets currently managed by the strategy
    /// @return Total amount of underlying asset in the GMX pool
    function totalAssets() public view override returns (uint256) {
        return gmxRouter.getPoolBalance(address(asset));
    }

    /// @notice Updates the vault address
    /// @param _newVault New vault address
    function setVault(address _newVault) public onlyOwner {
        if (_newVault == address(0)) revert ZeroAddress();

        emit VaultChanged(vault, _newVault, block.timestamp);

        vault = _newVault;
    }

    /// @notice Emergency withdrawal of all assets from GMX pool to vault
    /// @dev Callable only by owner
    function emergencyWithdraw() public onlyOwner {
        uint256 amount = totalAssets();

        gmxRouter.withdrawFromPool(address(asset), amount);

        asset.transfer(vault, amount);

        emit EmergencyWithdraw(amount, block.timestamp);
    }
}
