// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fadra is ERC20 {
    uint256 public immutable maxSupply = 6942000000 * 10 ** 18;
    uint256 private constant SECONDS_PER_YEAR = 31536000;
    uint256 private constant SCALE = 1e18; // min of 1 from Hholding added precision

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
        uint256 RPfee =  amountWithDecimals * 2 * 10 ** 2;
        uint256 fee =  amountWithDecimals * (85 * 10 ** 2) * 10 ** 2 ;

        //logic to add it to pools

        uint256 AfterFeeAmount = amountWithDecimals - (LPfee + RPfee + fee);

        //calculated and updated the amount after fee deduction
        _mint(msg.sender, AfterFeeAmount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // here goes the logic of deducting fee from transfer token (2% + 2% + 0.85%)
        //cover it in require
        uint256 LPfee = amount * 2 * 10 ** 2;
        uint256 RPfee =  amount * 2 * 10 ** 2;
        uint256 fee =  amount * (85 * 10 ** 2) * 10 ** 2 ;

        //logic to add it to pools(need pool wallets I think)

        uint256 AfterFeeAmount = amount - (LPfee + RPfee + fee);

        super._transfer(from, to, AfterFeeAmount);
    }

    /**
     * betai - progressive bonus
     * alphai - regressive penalty
     * Hholding
     * Sactivity
     */



    function betai(
        address _user
    ) public view returns (uint256) {
      
      //calculating betaBases
   uint256 BaseBetaMin; //some const
   uint256 BasebetaMax; //some const

   uint256 Multiplier; // this is reward pool/ Target Rewardpool , calculate it once we get the rewardpool wallet and total rewardpool

         // Constants for beta min and max
    uint256 betaMin = BaseBetaMin * Multiplier; 
    uint256 betaMax = BasebetaMax * Multiplier;
    //depends on basebeta-min-max

    // Maximum possible activity (D_max)
    uint256 maxActivity;// max activity constant

    //user's activity
     uint256 UserAct = userActivities[_user].transactionCount;

      uint256 beta =
            betaMin +
            ((betaMax - betaMin) * (maxActivity - UserAct)) /
            maxActivity; 

      return beta ; 
      //check if everything alright    
    }



    function alphai() public view returns (uint256) {}

    function Sactivity(address caller) public view returns (uint256) {
        /**
         * every user's transaction last transaction using (arr.length - 1) that will be last time stamp / 365
         *
         * if this is min then value one then return the value otherwise 1 will be return
         *
         */

        uint256 CallerTransactionCount = userActivities[caller]
            .transactionCount;
        uint256 averageTransaction = totalTransactions / totalUsers;

        return CallerTransactionCount / averageTransaction;
    }

    function Hholding(address caller) public view returns (uint256) {
        /**
         * userTransactions = each user transaction in minting + transfer (maintain through mapping and array)
         *
         * avgTransactions = sum of all user transactions / last address of mapping
         * we'll keep an counter that will point to end of mapping of address vs amount
         */

        uint256 lastTransactionTimeStamp = userActivities[caller]
            .lastTransactionTimeStamp;
        uint256 timeDifference = block.timestamp - lastTransactionTimeStamp;

        uint256 activity = (timeDifference * 1e18) / SECONDS_PER_YEAR;

        return activity > SCALE ? SCALE : activity;
    }
}