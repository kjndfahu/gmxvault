//SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import "../src/vault/GMXVault.sol";
import "../src/vault/GMXStrategy.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockGMXRouter.sol";

contract GMXStrategyTest is Test {
    GMXVault gmxVault;
    MockERC20 asset;
    GMXStrategy strategy;

    address user1 = vm.addr(1);
    address user2 = vm.addr(2);

    function setUp() public {
        asset = new MockERC20("Asset", "AST");

        MockGMXRouter gmxRouter = new MockGMXRouter();

        strategy = new GMXStrategy(address(asset), address(gmxRouter), address(0));

        gmxVault = new GMXVault(asset, strategy);

        strategy.setVault(address(gmxVault));

        asset.mint(user1, 1_000_000 ether);

        vm.prank(user1);
        asset.approve(address(gmxVault), type(uint256).max);
    }

    function testConstructorShouldRevertZeroAddress() public {
        MockGMXRouter router = new MockGMXRouter();

        vm.expectRevert(ZeroAddress.selector);
        new GMXStrategy(address(asset), address(0), address(gmxVault));
    }

    function testConstructorShouldRevertZeroAddressAsset() public {
        MockGMXRouter router = new MockGMXRouter();

        vm.expectRevert(ZeroAddress.selector);
        new GMXStrategy(address(0), address(router), address(gmxVault));
    }

    function testOnlyVaultModifierShouldRevertVaultNotSet() public {
        GMXStrategy newStrategy = new GMXStrategy(address(asset), address(1), address(0));

        vm.prank(user1);
        vm.expectRevert(VaultNotSet.selector);
        newStrategy.deposit(1 ether);
    }

    function testDepositShouldRevertZeroAmount() public {
        vm.startPrank(address(gmxVault));

        vm.expectRevert(ZeroAmount.selector);
        strategy.deposit(0);

        vm.stopPrank();
    }

    function testWithdrawShouldRevertZeroAmount() public {
        vm.startPrank(address(gmxVault));

        vm.expectRevert(ZeroAmount.selector);
        strategy.withdraw(0);

        vm.stopPrank();
    }

    // function testWithdrawShouldRevertInsufficientBalance() public {
    //     asset.mint(address(gmxVault), 500 ether);
    //     asset.transfer(address(strategy), 100);

    //     vm.startPrank(address(gmxVault));

    //     asset.approve(address(strategy), type(uint256).max);

    //     strategy.deposit(100 ether);

    //     vm.expectRevert(InsufficientBalance.selector);
    //     strategy.withdraw(200 ether);

    //     vm.stopPrank();
    // }

    function testOnlyVaultShouldRevertVaultNotSet() public {
        vm.prank(user1);

        vm.expectRevert(Unauthorized.selector);
        strategy.deposit(10 ether);

        vm.stopPrank();
    }

    function testSetVaultShouldRevertZeroAddress() public {
        vm.expectRevert(ZeroAddress.selector);
        strategy.setVault(address(0));
    }

    function testSetVault() public {
        vm.expectEmit(true, true, false, true);
        emit VaultChanged(address(gmxVault), address(2), block.timestamp);

        strategy.setVault(address(2));
    }

    // function testEmergencyWithdraw
}
