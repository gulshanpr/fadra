// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fadra is ERC20 {
    uint256 public immutable maxSupply = 6942000000 * 10 ** 18;
    uint256 private constant SECONDS_PER_YEAR = 31536000;
    uint256 private constant SCALE = 1e18; // min of 1 from Hholding added precision
    uint256 MaxTokenMinted = 0 * 10 ** 18
    

    struct UserActivity {
        uint256 transactionCount; // this will be used by Sactivity
        uint256 lastTransactionTimeStamp; // this will be used by Hholding
    }

    uint256 public totalTransactions; // increase this every time a transaction happens (minting or transfer)
    uint256 public totalUsers; // this will point to end of the mapping to calculate total unique user count
    // before increasing it, check if this address already exists in mapping or not
    mapping(address => UserActivity) public userActivities;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // include total supply here
    }

    function mint(uint256 amount) public {
        uint256 amountWithDecimals = amount * 10 ** 18;
        require(
            totalSupply() + amountWithDecimals <= maxSupply,
            "Minting exceeds max supply"
        );

        // here goes the logic of deducting fee from minting token (2% + 2% + 0.85%)
        //this should be wrapped in require, till Afterfee amount.
        uint256 LPfee = amountWithDecimals * 2 * 10 ** 2;
        uint256 RPfee = amountWithDecimals * 2 * 10 ** 2;
        uint256 fee = amountWithDecimals * (85 * 10 ** 2) * 10 ** 2;

        //logic to add it to pools

        uint256 AfterFeeAmount = amountWithDecimals - (LPfee + RPfee + fee);
        //updating the max token minted by any address, if yes then update (Dmax)
        if (AfterFeeAmount > MaxTokenMinted) {
            MaxTokenMinted = AfterFeeAmount
        }

        //calculated and updated the amount after fee deduction
        _mint(msg.sender, AfterFeeAmount);
        // increase counts
        totalTransactions = totalTransactions + 1;
        userActivities[msg.sender].transactionCount += 1;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // here goes the logic of deducting fee from transfer token (2% + 2% + 0.85%)
        //cover it in require
        uint256 LPfee = amount * 2 * 10 ** 2;
        uint256 RPfee = amount * 2 * 10 ** 2;
        uint256 fee = amount * (85 * 10 ** 2) * 10 ** 2;

        //logic to add it to pools(need pool wallets I think)

        uint256 AfterFeeAmount = amount - (LPfee + RPfee + fee);

        super._transfer(from, to, AfterFeeAmount);

        //logic to update dmax after transfers, if any 
        if(getTokenBalance(to) > MaxTokenMinted){
            MaxTokenMinted = getTokenBalance(to);
        }

        //increase transaction count
        totalTransactions = totalTransactions + 1;
        userActivities[msg.sender].transactionCount += 1;
    }

    //Reward Calculator

    function RewardCalc() public view returns (uint256) {
        //components and multipliers
        uint256 TotalReward; //get from reward pool
        uint256 Tokens; //total tokens held by users , what is the logic to calculate.
        uint256 Beta = betai(msg.sender); //betai
        uint256 Alpha = alphai(msg.sender); //alphai
        uint256 Sact = Sactivity(msg.sender); //Activity
        uint256 Shol = Hholding(msg.sender); //holding

        uint256 R1 = Tokens * (1 + Beta - Alpha) * (1 + Shol) * Sact;

        //according to formula we need to calculate a summation of R1 of all users.
        uint256 SumOfR1; //logic to calculate it, most probably dynamically calculate through iterating the mappings

        uint256 Reward = max(
            ((15 * 10 ** 2) * TotalReward),
            min(((999 * 10 ** 3) * TotalReward), (R1 / SumOfR1))
        );

        return Reward;
    }

    /**
     * betai - progressive bonus
     * alphai - regressive penalty
     * Hholding
     * Sactivity
     */

    function betai(address _user) public view returns (uint256) {
        //calculating betaBases
        uint256 BaseBetaMin; //some const
        uint256 BasebetaMax; //some const

        uint256 Multiplier = betaMultiplier(); // this is reward pool/ Target Rewardpool , calculate it once we get the rewardpool wallet and total rewardpool

        // Constants for beta min and max
        uint256 betaMin = BaseBetaMin * Multiplier;
        uint256 betaMax = BasebetaMax * Multiplier;
        //depends on basebeta-min-max

        // distribution function call
        uint256 tokenDistributionMulitplier = 1 - getTokenDistribution(_user);


        uint256 beta = betaMin +
            ((betaMax - betaMin) * tokenDistributionMulitplier);

        return beta;
        //check if everything alright
    }

    function alphai(address _user) public view returns (uint256) {
        // we will add more props if required.
        //calculating alphabases
        uint256 AlphaBaseMax; //some const
        uint256 AlphaBaseMin; //some const

        uint256 Multiplier = alphaMultiplier(); // this is reward pool/ Target Rewardpool , calculate it once we get the rewardpool wallet and total rewardpool

        //calculating alphaminmax
        uint256 Alphamax = AlphaBaseMax * Multiplier;
        uint256 Alphamin = AlphaBaseMin * Multiplier;

        // distribution function call
        uint256 tokenDistributionMulitplier = getTokenDistribution(_user);

        uint256 alpha = Alphamin +
            ((Alphamax - Alphamin) * tokenDistributionMulitplier);

        return alpha;
        //check for the formula here
    }

    function Hholding(address caller) public view returns (uint256) {
        /**
         * every user's last transaction using (arr.length - 1) that will be last time stamp / 365 (or just keep one varible to keep track fo last transaction timestamp)
         *
         * if this is min then value one then return the value otherwise 1 will be return
         *
         */

        uint256 lastTransactionTimeStamp = userActivities[caller]
            .lastTransactionTimeStamp;
        uint256 timeDifference = block.timestamp - lastTransactionTimeStamp;

        uint256 activity = (timeDifference * 1e18) / SECONDS_PER_YEAR;

        return activity > SCALE ? SCALE : activity;
    }

    function Sactivity(address caller) public view returns (uint256) {
        /**
         * userTransactions = each user transaction in minting + transfer (maintain through mapping and array)
         *
         * avgTransactions = sum of all user transactions / last address of mapping
         * we'll keep an counter that will point to end of mapping of address vs amount
         */

        uint256 CallerTransactionCount = userActivities[caller]
            .transactionCount;
        uint256 averageTransaction = totalTransactions / totalUsers;

        return CallerTransactionCount / averageTransaction;
    }

    // helper functions

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) public pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

    function getTokenDistribution(address _user) public pure returns (uint256) {
        // this will return the values of Di / Dmax that is 
       uint256 Di = getTokenBalance(_user);
       uint256 Dmax = MaxTokenMinted;

       return (Di / Dmax) ; //check please
    }

    function betaMultiplier() public pure returns (uint256) {
        // this will return the values of RewardPool / TargetRewardPool
    }

    function alphaMultiplier() public pure returns (uint256) {
        // this will return the values of TargetActivity / TotalActivity
        uint256 TargetActivity = 1200 // constant
        uint256 TotalActivity = totalTransactions;

        return (TargetActivity / TotalActivity); // check please
    }

     // Function to get the balance of a user for this token
    function getTokenBalance(address user) public view returns (uint256) {
        return balanceOf(user); // `balanceOf` is inherited from ERC20
    }
}
