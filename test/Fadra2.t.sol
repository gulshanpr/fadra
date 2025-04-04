// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Fadra} from "../src/Fadra.sol";
import "forge-std/console.sol";

contract FadraTest is Test {
    Fadra fadra;

    function setUp() public {
        address lpWallet = makeAddr("lpWallet");
        address marketingWallet = makeAddr("marketingWallet");
        address deployer = makeAddr("deployer");

        vm.startPrank(deployer);

        console.log("Deployer address (msg.sender) is:", deployer);

        fadra = new Fadra("Fadra Token", "FDR", lpWallet, marketingWallet);

        console.log("Owner address set in Fadra contract:", fadra.owner());
        console.log(
            "Balance of deployer after deploying Fadra:",
            fadra.balanceOf(deployer)
        );
    }

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
        console.log("Beta ends----------------------------------");
        fadra.debugGetTokenDistribution(msg.sender);
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
        console.log("Beta ends----------------------------------");
        fadra.debugBetai(msg.sender);
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
        console.log("Alphai ends----------------------------------");
        fadra.debugAlphai(msg.sender);
    }

    function testHholding() public {
        // console.log("Initial block.timestamp:", block.timestamp);
        vm.warp(1737013266);
        // console.log("timestamp", block.timestamp);
        fadra.setUserActivity(msg.sender, 1000, 5, 1736581266, 92);
        console.log("Hholding returned value ", fadra.Hholding(msg.sender));
        console.log("Hholding ends----------------------------------");
        fadra.debugHholding(msg.sender);
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
        console.log("Sactivity ends----------------------------------");
        fadra.debugSactivity(msg.sender);
    }

    function testUpdateUserActivity() public {
        fadra.setUserActivity(msg.sender, 23443e18, 34, 1737013245, 1000e18);
        fadra.setTotalTransaction(12345);
        vm.warp(1737013266);
        console.log(block.timestamp);
        fadra._updateUserActivity(msg.sender);
        vm.warp(1737013269);
        console.log(block.timestamp);
        fadra._updateUserActivity(msg.sender);
        (
            uint256 balanc,
            uint256 transactionCount,
            uint256 lastTransactionTimestamp,
            uint reward
        ) = fadra.getUserActivity(msg.sender);

        console.log("balance", balanc);
        console.log("transactionCount", transactionCount);
        console.log("lastTransactionTimestamp", lastTransactionTimestamp);
        console.log("reward", reward);
        console.log("total transaction count", fadra.getTotalTransaction());
        console.log("--------------------end");
        fadra._DebugupdateUserActivity(msg.sender);
    }

    function testUpdateMaxTokenHolder() public {
        address deployer = makeAddr("deployer");

        vm.startPrank(deployer);

        console.log(
            "Max token holder after setting baseline:",
            fadra.getMaxTokenHolder()
        );
        fadra.setMaxTokenHolder(99999999);
        console.log(
            "Max token holder after setting baseline:",
            fadra.getMaxTokenHolder()
        );
        fadra._updateMaxTokenHolder(deployer);
        console.log(
            "Max token holder after setting baseline: after updating",
            fadra.getMaxTokenHolder()
        );

        vm.stopPrank();
    }

    function testFailMint() public {
        fadra.mint(20);
        // this test is failing means test is passing
    }

    function testDebugSactivity() public {
        fadra.debugSactivity(msg.sender);
    }

    // function testFallBack() public {
    //     vm.warp();
    // }

    // function testTransfer() public {
    //     address recipiant = makeAddr("recipiant");
    //     address deployer = makeAddr("deployer");

    //     vm.startPrank(deployer);
    //     fadra.approve(address(fadra), type(uint256).max);
    //     fadra.transfer(deployer, recipiant, (100 * 1e18));

    //     console.log("deployer balance", fadra.balanceOf(deployer));
    //     console.log("recipant balance", fadra.balanceOf(recipiant));

    //     // fadra._transfer(deployer, recipiant, amount);
    // }

    // function testRewardCalc() public {
    //     console.log("betai starts--------------------------------");
    //     fadra.setMaxTokenHolder(1000);
    //     console.log("setted maxTokenHolder Value: ", fadra.getMaxTokenHolder());
    //     fadra.setTotalRewardPoolValue(2000);
    //     console.log(
    //         "setted totalRewardPool value: ",
    //         fadra.getTotalRewardPoolValue()
    //     );
    //     console.log(fadra.betai(msg.sender));
    //     console.log("betai ends----------------------------------");
    //     console.log("alphai starts----------------------------------");
    //     fadra.setTotalTransaction(800);
    //     console.log(
    //         "setted totalTransaction value: ",
    //         fadra.getTotalTransaction()
    //     );
    //     console.log(fadra.alphai(msg.sender));
    //     console.log("alphai ends----------------------------------");
    //     console.log("Hholding starts----------------------------------");
    //     vm.warp(1737013266);
    //     // console.log("timestamp", block.timestamp);
    //     fadra.setUserActivity(msg.sender, 1000, 100, 1736408466, 92);
    //     console.log("Hholding returned value ", fadra.Hholding(msg.sender));
    //     console.log("Hholding ends----------------------------------");
    //     console.log("Sactivity ends----------------------------------");
    //     fadra.setTotalUser(50);
    //     console.log("setted to// function testFallBack() public {
    //     vm.warp();
    // }

    // function testTransfer() public {
    //     address recipiant = makeAddr("recipiant");
    //     address deployer = makeAddr("deployer");

    //     vm.startPrank(deployer);
    //     fadra.approve(address(fadra), type(uint256).max);
    //     fadra.transfer(deployer, recipiant, (100 * 1e18));

    //     console.log("deployer balance", fadra.balanceOf(deployer));
    //     console.log("recipant balance", fadra.balanceOf(recipiant));

    //     // fadra._transfer(deployer, recipiant, amount);
    // }

    // function testRewardCalc() public {
    //     console.log("betai starts--------------------------------");
    //     fadra.setMaxTokenHolder(1000);
    //     console.log("setted maxTokenHolder Value: ", fadra.getMaxTokenHolder());
    //     fadra.setTotalRewardPoolValue(2000);
    //     console.log(
    //         "setted totalRewardPool value: ",
    //         fadra.getTotalRewardPoolValue()
    //     );
    //     console.log(fadra.betai(msg.sender));
    //     console.log("betai ends----------------------------------");
    //     console.log("alphai starts----------------------------------");
    //     fadra.setTotalTransaction(800);
    //     console.log(
    //         "setted totalTransaction value: ",
    //         fadra.getTotalTransaction()
    //     );
    //     console.log(fadra.alphai(msg.sender));
    //     console.log("alphai ends----------------------------------");
    //     console.log("Hholding starts----------------------------------");
    //     vm.warp(1737013266);
    //     // console.log("timestamp", block.timestamp);
    //     fadra.setUserActivity(msg.sender, 1000, 100, 1736408466, 92);
    //     console.log("Hholding returned value ", fadra.Hholding(msg.sender));
    //     console.log("Hholding ends----------------------------------");
    //     console.log("Sactivity ends----------------------------------");
    //     fadra.setTotalUser(50);
    //     console.log("setted totalUsers value is", fadra.getTotalUser());

    //     console.log("Sactivity returned value ", fadra.Sactivity(msg.sender));
    //     console.log("Sactivity ends----------------------------------");

    //     console.log("reward calc ", fadra.RewardCalc(msg.sender));
    // }talUsers value is", fadra.getTotalUser());

    //     console.log("Sactivity returned value ", fadra.Sactivity(msg.sender));
    //     console.log("Sactivity ends----------------------------------");

    //     console.log("reward calc ", fadra.RewardCalc(msg.sender));
    // }
}
