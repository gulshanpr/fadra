
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Fadra.sol";

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
    assertEq(fadra.balanceOf(user1), expectedUser1Balance, "User1 balance incorrect after transfer");

    // Check `to` (user2) balance is increased
    uint256 expectedUser2Balance = user2InitialBalance + afterFeeAmount;
    assertEq(fadra.balanceOf(user2), expectedUser2Balance, "User2 balance incorrect after transfer");

    // Check reward pool is increased
    uint256 expectedRewardPool = rewardPoolInitial + RPfee;
    assertEq(fadra.totalRewardPool(), expectedRewardPool, "Reward pool balance incorrect after transfer");

    // Check marketing wallet balance is increased
    uint256 expectedMarketingWalletBalance = marketingWalletInitial + marketingFee;
    assertEq(fadra.balanceOf(marketingWallet), expectedMarketingWalletBalance, "Marketing wallet balance incorrect after transfer");

    // Check LP wallet balance is increased
    uint256 expectedLPWalletBalance = lpWalletInitial + LPfee;
    assertEq(fadra.balanceOf(lpWallet), expectedLPWalletBalance, "LP wallet balance incorrect after transfer");
}


//     // Test fee calculation logic
//     function testCalculateFees() public {
//         uint256 amount = 1000 * 10 ** 18;

//         (uint256 lpFee, uint256 rpFee, uint256 marketingFee, uint256 afterFee) = fadra._calculateFees(amount);

//         assertEq(lpFee, (amount * 2) / 100);
//         assertEq(rpFee, (amount * 2) / 100);
//         assertEq(marketingFee, (amount * 85) / 10000);
//         assertEq(afterFee, amount - (lpFee + rpFee + marketingFee));
//     }

//     // Test reward calculation
//     function testRewardCalculation() public {
//         vm.prank(user1);
//         uint256 reward = fadra.RewardCalc(user1);

//         // Ensure reward is calculated correctly and updates user reward
//         assertGt(reward, 0);
//         //
//     }

//     // Test betai calculation
//     function testBetai() public {
//         uint256 beta = fadra.betai(user1);

//         // Ensure beta is within expected range
//         assertGt(beta, 2e16); // BASE_BETA_MIN
//         assertLt(beta, 15e16); // BASE_BETA_MAX
//     }

//     // Test alphai calculation
//     function testAlphai() public {
//         uint256 alpha = fadra.alphai(user1);

//         // Ensure alpha is within expected range
//         assertGt(alpha, 1e16); // BASE_ALPHA_MIN
//         assertLt(alpha, 1e17); // BASE_ALPHA_MAX
//     }

//     // Test holding multiplier
//     function testHholding() public {
//         vm.warp(block.timestamp + 1000); // Simulate time passage
//         uint256 holdingMultiplier = fadra.Hholding(user1);

//         // Ensure holding multiplier is calculated correctly
//         assertGt(holdingMultiplier, 0);
//         assertLe(holdingMultiplier, 1e18);
//     }

//     // Test activity multiplier
//     function testSactivity() public {
//         uint256 activityMultiplier = fadra.Sactivity(user1);

//         // Ensure activity multiplier is calculated correctly
//         assertGt(activityMultiplier, 0);
//         assertLe(activityMultiplier, 1e18);
//     }

//     // Test fallback condition
//     function testFallbackCondition() public {
//         vm.warp(block.timestamp + fadra.SECONDS_IN_THREE_MONTHS());
//         bool triggered = fadra.fallBack();

//         // Verify fallback behavior
//         assertTrue(triggered);
//         assertEq(fadra.totalRewardPool(), 0);
//     }

//     // Test token distribution calculation
//     function testTokenDistribution() public {
//         uint256 distribution = fadra.getTokenDistribution(user1);

//         // Ensure token distribution is valid
//         assertGt(distribution, 0);
//         assertLe(distribution, fadra.SCALE());
//     }

//     // Test user activity updates
//   function testUpdateUserActivity() public {
//     vm.prank(user1);
//     fadra.transfer(user2, 100 * 10 ** 18);

//     // Destructure the user activity
//     (uint256 balance, uint256 transactionCount, uint256 lastTransactionTimestamp, uint256 reward) = fadra.userActivities(user1);

//     // Validate activity updates
//     assertEq(transactionCount, 1); // Check transaction count incremented
//     assertGt(lastTransactionTimestamp, 0); // Ensure timestamp updated
// }


//     // Test max token holder update
//     function testUpdateMaxTokenHolder() public {
//         vm.prank(user1);
//         fadra.transfer(user2, 100 * 10 ** 18);

//         // Validate max token holder update
//         assertEq(fadra.maxTokenHolder(), fadra.balanceOf(user1));
//     }
}