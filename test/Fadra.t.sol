// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Fadra.sol";

// contract FadraTest is Test {
//     Fadra public fadra;
//     address public owner;
//     address public lpWallet;
//     address public marketingWallet;
//     address public user1;
//     address public user2;

contract FadraTest is Test {
    Fadra fadra;
    address owner = address(this);
    address lpWallet = address(0x2);
    address marketingWallet = address(0x3);
    address user1 = address(0x4);
    address user2 = address(0x5);
    uint256 globalSummation = 3 * 1e18;

    function setUp() public {
        // Deploy the Fadra contract
        fadra = new Fadra("FadraToken", "FADRA", lpWallet, marketingWallet);

        // Owner approves the contract to deduct fees for transfers
        vm.prank(owner);
        fadra.approve(address(fadra), type(uint256).max);

        // Transfer tokens to user1 (fees apply)
        vm.prank(owner);
        fadra.transfer(user1, 1000 * 10 ** 18);

        // Transfer tokens to user2 (fees apply)
        vm.prank(owner);
        fadra.transfer(user2, 500 * 10 ** 18);

        // Users approve the contract to deduct fees for future transactions
        vm.prank(user1);
        fadra.approve(address(fadra), type(uint256).max);

        vm.prank(user2);
        fadra.approve(address(fadra), type(uint256).max);
    }

    // Test mint function
    // function testMint() public {
    //     vm.prank(owner);
    //     fadra.mint(500);

    //     assertEq(fadra.totalSupply(), 6_942_000_500 * 10 ** 18);
    // }

    // Test transfer function and fee deductions
    function testTransferAndFeeDistribution() public {
        uint256 transferAmount = 100 * 10 ** 18; // Transfer 100 tokens
        uint256 user1InitialBalance = fadra.balanceOf(user1);
        uint256 user2InitialBalance = fadra.balanceOf(user2);
        uint256 rewardPoolInitial = fadra.totalRewardPool();
        uint256 marketingWalletInitial = fadra.balanceOf(marketingWallet);
        uint256 lpWalletInitial = fadra.balanceOf(lpWallet);

        // Perform transfer from user1 to user2
        vm.prank(user1);
        fadra.transfer(user2, transferAmount);

        // Calculate fees
        (
            uint256 LPfee,
            uint256 RPfee,
            uint256 marketingFee,
            uint256 afterFeeAmount
        ) = fadra._calculateFees(transferAmount);

        // Check `from` (user1) balance is reduced
        uint256 expectedUser1Balance = user1InitialBalance - transferAmount;
        assertEq(
            fadra.balanceOf(user1),
            expectedUser1Balance,
            "User1 balance incorrect after transfer"
        );

        // Check `to` (user2) balance is increased
        uint256 expectedUser2Balance = user2InitialBalance + afterFeeAmount;
        assertEq(
            fadra.balanceOf(user2),
            expectedUser2Balance,
            "User2 balance incorrect after transfer"
        );

        // Check reward pool is increased
        uint256 expectedRewardPool = rewardPoolInitial + RPfee;
        assertEq(
            fadra.totalRewardPool(),
            expectedRewardPool,
            "Reward pool balance incorrect after transfer"
        );

        // Check marketing wallet balance is increased
        uint256 expectedMarketingWalletBalance = marketingWalletInitial +
            marketingFee;
        assertEq(
            fadra.balanceOf(marketingWallet),
            expectedMarketingWalletBalance,
            "Marketing wallet balance incorrect after transfer"
        );

        // Check LP wallet balance is increased
        uint256 expectedLPWalletBalance = lpWalletInitial + LPfee;
        assertEq(
            fadra.balanceOf(lpWallet),
            expectedLPWalletBalance,
            "LP wallet balance incorrect after transfer"
        );
    }
    
}
