// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import "forge-std/Test.sol";
// import "../src/Fadra.sol";

// contract FadraTest is Test {
//     Fadra public fadra;
//     address public owner;
//     address public lpWallet;
//     address public marketingWallet;
//     address public user1;
//     address public user2;

//     // Constants for testing
//     uint256 constant INITIAL_SUPPLY = 6_942_000_000 * 10 ** 18;
//     uint256 constant INITIAL_USER_BALANCE = 1_000_000 * 10 ** 18;

//     function setUp() public {
//         // Setup addresses
//         owner = address(this); // Test contract is the owner
//         lpWallet = makeAddr("lpWallet");
//         marketingWallet = makeAddr("marketingWallet");
//         user1 = makeAddr("user1");
//         user2 = makeAddr("user2");

//         // Deploy contract - all tokens are minted to owner (this test contract)
//         fadra = new Fadra("Fadra Token", "FDR", lpWallet, marketingWallet);

//         // Verify owner (test contract) has all initial supply
//         assertEq(
//             fadra.balanceOf(owner),
//             INITIAL_SUPPLY,
//             "Owner should have all initial supply"
//         );

//         // Owner approves the contract to spend tokens
//         fadra.approve(address(fadra), type(uint256).max);

//         // Transfer initial balances to test users using transferFrom
//         fadra.transferFrom(owner, user1, 1_000_000 * 10 ** 18);
//         fadra.transferFrom(owner, user2, 1_000_000 * 10 ** 18);

//         // Set approvals for test users
//         vm.prank(user1);
//         fadra.approve(address(fadra), type(uint256).max);

//         vm.prank(user2);
//         fadra.approve(address(fadra), type(uint256).max);
//     }

//     // Test initial setup and balances
//     function testInitialSetup() public {
//         assertEq(fadra.name(), "Fadra Token");
//         assertEq(fadra.symbol(), "FDR");
//         assertEq(owner, fadra.owner());
//         assertEq(lpWallet, fadra.lpWallet());
//         assertEq(marketingWallet, fadra.marketingWallet());

//         // Verify initial distributions
//         assertEq(
//             fadra.balanceOf(user1),
//             INITIAL_USER_BALANCE,
//             "User1 should have initial balance"
//         );
//         assertEq(
//             fadra.balanceOf(user2),
//             INITIAL_USER_BALANCE,
//             "User2 should have initial balance"
//         );
//         assertEq(
//             fadra.balanceOf(owner),
//             INITIAL_SUPPLY - (2 * INITIAL_USER_BALANCE),
//             "Owner should have remaining supply"
//         );
//     }

//     // Test basic transfer
//     function testTransfer() public {
//         uint256 transferAmount = 100 * 10 ** 18;
//         uint256 initialBalance1 = fadra.balanceOf(user1);
//         uint256 initialBalance2 = fadra.balanceOf(user2);

//         vm.startPrank(user1);
//         fadra.transfer(user2, transferAmount);
//         vm.stopPrank();

//         // Calculate expected fees
//         (
//             uint256 LPfee,
//             uint256 RPfee,
//             uint256 marketingFee,
//             uint256 afterFeeAmount
//         ) = fadra._calculateFees(transferAmount);

//         assertEq(
//             fadra.balanceOf(user1),
//             initialBalance1 - transferAmount,
//             "Incorrect sender balance"
//         );
//         assertEq(
//             fadra.balanceOf(user2),
//             initialBalance2 + afterFeeAmount,
//             "Incorrect receiver balance"
//         );
//         assertEq(
//             fadra.balanceOf(lpWallet),
//             LPfee,
//             "Incorrect LP wallet balance"
//         );
//         assertEq(
//             fadra.balanceOf(marketingWallet),
//             marketingFee,
//             "Incorrect marketing wallet balance"
//         );
//     }

//     // Test fee calculation
//     function testFeeCalculation() public {
//         uint256 amount = 1000 * 10 ** 18;
//         (
//             uint256 LPfee,
//             uint256 RPfee,
//             uint256 marketingFee,
//             uint256 afterFeeAmount
//         ) = fadra._calculateFees(amount);

//         assertEq(LPfee, (amount * 2) / 100, "Incorrect LP fee");
//         assertEq(RPfee, (amount * 2) / 100, "Incorrect RP fee");
//         assertEq(
//             marketingFee,
//             (amount * 85) / 10000,
//             "Incorrect marketing fee"
//         );
//         assertEq(
//             afterFeeAmount,
//             amount - (LPfee + RPfee + marketingFee),
//             "Incorrect after fee amount"
//         );
//     }
// }
