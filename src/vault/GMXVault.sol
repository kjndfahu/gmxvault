// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IGMXVault.sol";
import "../utils/Errors.sol";

/// @title GMX Vault
/// @author
/// @notice Vault contract following ERC4626 standard to manage deposits into GMX Strategy
/// @dev Integrates with a strategy that implements `IStrategy`. Users deposit ERC20 `asset` tokens and receive shares.
contract GMXVault is ERC4626, Ownable, IGMXVault {
    /// @notice Strategy contract that handles underlying asset management
    IStrategy public strategy;

    /// @notice Constructs the GMXVault
    /// @param _asset The ERC20 token managed by this vault
    /// @param _strategy The strategy contract handling deposits and withdrawals
    constructor(IERC20 _asset, IStrategy _strategy)
        ERC20("GMX Vault Share", "gMX")
        ERC4626(_asset)
        Ownable(msg.sender)
    {
        if (address(_asset) == address(0)) revert ZeroAddress();
        if (address(_strategy) == address(0)) revert ZeroAddress();

        strategy = _strategy;
    }

    /// @notice Deposits assets into the vault and mints corresponding shares
    /// @param _assets Amount of underlying assets to deposit
    /// @param _receiver Address receiving the vault shares
    /// @return shares Amount of shares minted to the receiver
    function deposit(uint256 _assets, address _receiver) public override(ERC4626, IGMXVault) returns (uint256 shares) {
        if (_assets <= 0) revert ZeroAmount();
        if (_receiver == address(0)) revert ZeroAddress();

        shares = previewDeposit(_assets);
        if (shares == 0) revert ZeroShares();

        IERC20(asset()).transferFrom(msg.sender, address(this), _assets);
        IERC20(asset()).approve(address(strategy), _assets);
        strategy.deposit(_assets);

        _mint(_receiver, shares);
    }

    /// @notice Withdraws assets from the vault by burning shares
    /// @param _assets Amount of underlying assets to withdraw
    /// @param _receiver Address receiving the underlying assets
    /// @param _owner Address of the shares owner
    /// @return shares Amount of shares burned
    function withdraw(uint256 _assets, address _receiver, address _owner)
        public
        override(ERC4626, IGMXVault)
        returns (uint256 shares)
    {
        if (_assets <= 0) revert ZeroAmount();
        if (_receiver == address(0) || _owner == address(0)) revert ZeroAddress();

        shares = convertToShares(_assets);
        if (shares == 0) revert ZeroShares();

        uint256 ownerBalance = balanceOf(_owner);
        if (ownerBalance < shares) revert InsufficientBalance();

        if (msg.sender != _owner) {
            _spendAllowance(_owner, msg.sender, shares);
        }

        _burn(_owner, shares);

        strategy.withdraw(_assets);

        IERC20(asset()).transfer(_receiver, _assets);
    }

    /// @notice Returns the total assets managed by the vault
    /// @return Total underlying assets held by the strategy
    function totalAssets() public view override(ERC4626, IGMXVault) returns (uint256) {
        return strategy.totalAssets();
    }
}
