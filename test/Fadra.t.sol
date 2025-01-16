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

        // Gulshan setup config start
        // address lpWallet = makeAddr("lpWallet");
        // address marketingWallet = makeAddr("marketingWallet");
        // address deployer = makeAddr("deployer");

        // vm.startPrank(deployer);

        // console.log("Deployer address (msg.sender) is:", deployer);

        // fadra = new Fadra("Fadra Token", "FDR", lpWallet, marketingWallet);

        // console.log("Owner address set in Fadra contract:", fadra.owner());
        // console.log(
        //     "Balance of deployer after deploying Fadra:",
        //     fadra.balanceOf(deployer)
        // );

        // Gulshan setup config end
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

    // Gulshan's test
    function testCalculateFees() public {
        uint256 amount = 1000;

        (
            uint256 LPfee,
            uint256 RPfee,
            uint256 marketingFee,
            uint256 afterFeeAmount
        ) = fadra._calculateFees(amount);

        console.log("Input Amount: ", amount);
        console.log("LP Fee (2%): ", LPfee);
        console.log("RP Fee (2%): ", RPfee);
        console.log("Marketing Fee (0.85%): ", marketingFee);
        console.log("Amount After Fees: ", afterFeeAmount);

        assertEq(LPfee, 20, "LP fee should be 2% of the amount");
        assertEq(RPfee, 20, "RP fee should be 2% of the amount");
        assertEq(
            marketingFee,
            8,
            "Marketing fee should be 0.85% of the amount"
        );
        assertEq(
            afterFeeAmount,
            952,
            "After-fee amount should match expected value"
        );
    }

    function testMin() public {
        uint256 min = fadra.min(10_000_000, 200_000);
        console.log("min value is", min);
    }

    function testMax() public {
        uint256 max = fadra.max(10_000_000, 200_000);
        console.log("max value is", max);
    }

    function testGetTokenDistribution() public {
        fadra.setMaxTokenHolder(1000);
        console.log("setted maxTokenHolder Value: ", fadra.getMaxTokenHolder());
        uint256 tokenDistribution = fadra.getTokenDistribution(msg.sender);
        console.log("Di/Dmax is: ", tokenDistribution);
    }

    function testBetai() public {
        fadra.setMaxTokenHolder(1000);
        console.log("setted maxTokenHolder Value: ", fadra.getMaxTokenHolder());
        fadra.setTotalRewardPoolValue(1200);
        console.log(
            "setted totalRewardPool value: ",
            fadra.getTotalRewardPoolValue()
        );
        console.log(fadra.betai(msg.sender));
    }

    function testAlphai() public {
        fadra.setMaxTokenHolder(1000);
        console.log("setted maxTokenHolder Value: ", fadra.getMaxTokenHolder());
        fadra.setTotalTransaction(600);
        console.log(
            "setted totalTransaction value: ",
            fadra.getTotalTransaction()
        );
        console.log(fadra.alphai(msg.sender));
    }

    function testHholding() public {
        // console.log("Initial block.timestamp:", block.timestamp);
        vm.warp(1737013266);
        // console.log("timestamp", block.timestamp);
        fadra.setUserActivity(msg.sender, 1000, 5, 1736581266, 92);
        console.log("Hholding returned value ", fadra.Hholding(msg.sender));
    }

    function testSactivity() public {
        fadra.setUserActivity(msg.sender, 1000, 5, 1736581266, 92);
        fadra.setTotalTransaction(600);
        console.log(
            "setted totalTransaction value: ",
            fadra.getTotalTransaction()
        );
        fadra.setTotalUser(50);
        console.log("setted totalUsers value is", fadra.getTotalUser());

        console.log("Sactivity returned value ", fadra.Sactivity(msg.sender));
    }

    function testRewardCalc() public {
        console.log("betai starts--------------------------------");
        fadra.setMaxTokenHolder(1000);
        console.log("setted maxTokenHolder Value: ", fadra.getMaxTokenHolder());
        fadra.setTotalRewardPoolValue(2000);
        console.log(
            "setted totalRewardPool value: ",
            fadra.getTotalRewardPoolValue()
        );
        console.log(fadra.betai(msg.sender));
        console.log("betai ends----------------------------------");
        console.log("alphai starts----------------------------------");
        fadra.setTotalTransaction(800);
        console.log(
            "setted totalTransaction value: ",
            fadra.getTotalTransaction()
        );
        console.log(fadra.alphai(msg.sender));
        console.log("alphai ends----------------------------------");
        console.log("Hholding starts----------------------------------");
        vm.warp(1737013266);
        // console.log("timestamp", block.timestamp);
        fadra.setUserActivity(msg.sender, 1000, 100, 1736408466, 92);
        console.log("Hholding returned value ", fadra.Hholding(msg.sender));
        console.log("Hholding ends----------------------------------");
        console.log("Sactivity ends----------------------------------");
        fadra.setTotalUser(50);
        console.log("setted totalUsers value is", fadra.getTotalUser());

        console.log("Sactivity returned value ", fadra.Sactivity(msg.sender));
        console.log("Sactivity ends----------------------------------");

        console.log("reward calc ", fadra.RewardCalc(msg.sender));
    }
}
