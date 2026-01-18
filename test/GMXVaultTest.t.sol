//SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import "../src/vault/GMXVault.sol";
import "../src/vault/GMXStrategy.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockGMXRouter.sol";

contract GMXVaultTest is Test {
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

    function testDepositShouldRevertZeroAmount() public {
        vm.startPrank(user2);

        vm.expectRevert(ZeroAmount.selector);
        gmxVault.deposit(0, user1);

        vm.stopPrank();
    }

    function testDepositShouldRevertZeroAddress() public {
        vm.startPrank(user2);

        vm.expectRevert(ZeroAddress.selector);
        gmxVault.deposit(10, address(0));

        vm.stopPrank();
    }

    // function testDepositShouldRevertZeroShares() public {
    //     vm.startPrank(user1);
    //     gmxVault.deposit(1_000_000 ether, user1);
    //     vm.stopPrank();

    //     vm.prank(address(gmxVault));
    //     asset.approve(address(strategy), 1_000_000 ether);

    //     uint256 totalAssets = gmxVault.totalAssets();
    //     assertEq(totalAssets, 1_000_000 ether);
    //     uint256 totalShares = gmxVault.totalSupply();
    //     assertEq(totalShares, 1_000_000 ether);

    //     vm.startPrank(user2);
    //     vm.expectRevert(ZeroShares.selector);
    //     gmxVault.deposit(1, user2);
    //     vm.stopPrank();

    // }

    function testDeposit() public {
        vm.startPrank(user1);
        uint256 shares = gmxVault.deposit(1_000_000 ether, user1);
        vm.stopPrank();

        vm.prank(address(gmxVault));
        asset.approve(address(strategy), 1_000_000 ether);

        assertEq(gmxVault.totalAssets(), shares);
        assertEq(gmxVault.totalSupply(), shares);
        assertEq(gmxVault.balanceOf(user1), shares);
        assertEq(asset.balanceOf(address(strategy.gmxRouter())), 1_000_000 ether);
    }

    function testWithdrawShouldRevertZeroAmount() public {
        vm.startPrank(user2);

        vm.expectRevert(ZeroAmount.selector);
        gmxVault.deposit(0, user2);

        vm.stopPrank();
    }

    function testWithdrawShouldRevertZeroAddress() public {
        vm.startPrank(user2);

        vm.expectRevert(ZeroAddress.selector);
        gmxVault.deposit(10, address(0));

        vm.stopPrank();
    }

    function testWithdrawInsufficientBalance() public {
        vm.startPrank(user1);

        gmxVault.deposit(100 ether, user1);

        vm.expectRevert(InsufficientBalance.selector);
        gmxVault.withdraw(200 ether, user1, user1);

        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user1);

        gmxVault.deposit(999_999 ether, user1);
        assertEq(strategy.totalAssets(), 999_999 ether);

        gmxVault.withdraw(999_999 ether, user1, user1);

        assertEq(asset.balanceOf(user1), 1_000_000 ether);

        vm.stopPrank();
    }

    function testTotalAssets() public {
        vm.startPrank(user1);

        gmxVault.deposit(10 ether, user1);

        assertEq(strategy.totalAssets(), 10 ether);

        vm.stopPrank();
    }
}
