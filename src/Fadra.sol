// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Fadra is ERC20 {
    uint256 public immutable maxSupply = 6942000000 * 10 ** 18;
    uint256 private constant SECONDS_PER_YEAR = 31536000;
    uint256 private constant SCALE = 1e18; // min of 1 from Hholding added precision
    uint256 totalRewardPool; // this will be used to keep track how much this contract is holding token
    address rewardToken;
    uint256 maxTokenHolder = 0 * 10 ** 18;

    // wallets
    address lpWallet;
    address marketingWallet;
    address thisContractAddress;

    // summation of Ri denominator for all users
    mapping(address => uint256) public userContribution; // Tracks each user's current contribution
    uint256 public globalSummation; // Global summation of all contributions

    struct UserActivity {
        uint256 balance;
        uint256 transactionCount; // this will be used by Sactivity
        uint256 lastTransactionTimeStamp; // this will be used by Hholding
    }

    uint256 public totalTransactions; // increase this every time a transaction happens (minting or transfer)
    uint256 public totalUsers; // this will point to end of the mapping to calculate total unique user count
    // before increasing it, check if this address already exists in mapping or not
    mapping(address => UserActivity) public userActivities;

    constructor(
        string memory name,
        string memory symbol,
        address _lpWallet,
        address _marketingWallet
    ) ERC20(name, symbol) {
        // include total supply here
        lpWallet = _lpWallet;
        marketingWallet = _marketingWallet;
        rewardToken = address(this);
        thisContractAddress = address(this);
    }

    function mint(uint256 amount) public {
        uint256 amountWithDecimals = amount * 10 ** 18;
        require(
            totalSupply() + amountWithDecimals <= maxSupply,
            "Minting exceeds max supply"
        );

        uint256 LPfee = (amountWithDecimals * 2) / 100; // 2% for Liquidity Pool
        uint256 RPfee = (amountWithDecimals * 2) / 100; // 2% for Reward Pool
        uint256 marketingFee = (amountWithDecimals * 85) / 10000; // 0.85% for Marketing

        uint256 totalFee = LPfee + RPfee + marketingFee;
        uint256 AfterFeeAmount = amountWithDecimals - totalFee;

        _mint(msg.sender, AfterFeeAmount);

        // Add RPfee to the reward pool
        totalRewardPool += RPfee;

        // Distribute fees to respective wallets
        IERC20(rewardToken).transfer(lpWallet, LPfee);
        IERC20(rewardToken).transfer(marketingWallet, marketingFee);

        // to check if this guy is the largest holder
        uint256 userHolding = balanceOf(msg.sender);
        if (userHolding > maxTokenHolder) {
            maxTokenHolder = userHolding;
        }

        // Increment transaction count
        totalTransactions++;
        userActivities[msg.sender].transactionCount++;
        userActivities[msg.sender].lastTransactionTimeStamp = block.timestamp;
        updateUserContribution(
            msg.sender,
            balanceOf(msg.sender),
            betai(msg.sender),
            alphai(msg.sender),
            Hholding(msg.sender),
            Sactivity(msg.sender)
        );
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 LPfee = (amount * 2) / 100; // 2% for Liquidity Pool
        uint256 RPfee = (amount * 2) / 100; // 2% for Reward Pool
        uint256 marketingFee = (amount * 85) / 10000; // 0.85% for Marketing

        uint256 totalFee = LPfee + RPfee + marketingFee;

        // Ensure the user has approved enough for the fees (totalFee)
        uint256 allowance = IERC20(rewardToken).allowance(from, address(this));
        require(allowance >= totalFee, "Not enough allowance for fees");

        // Single transferFrom call for total fees
        IERC20(rewardToken).transferFrom(from, address(this), totalFee);

        // Distribute fees to respective wallets
        IERC20(rewardToken).transfer(lpWallet, LPfee);
        IERC20(rewardToken).transfer(marketingWallet, marketingFee);

        // Add RPfee to the reward pool
        totalRewardPool += RPfee;

        uint256 afterFeeAmount = amount - totalFee;

        super._transfer(from, to, afterFeeAmount);

        // Update max token holder
        uint256 fromUserHolding = balanceOf(from);
        uint256 toUserHolding = balanceOf(to);

        if (fromUserHolding > maxTokenHolder) {
            maxTokenHolder = fromUserHolding;
        }

        if (toUserHolding > maxTokenHolder) {
            maxTokenHolder = toUserHolding;
        }

        // Increment transaction count for both sender and receiver
        totalTransactions++;
        userActivities[from].transactionCount++;
        userActivities[to].transactionCount++; // Track receiver's transaction count as well
        userActivities[from].lastTransactionTimeStamp = block.timestamp;
        updateUserContribution(
            msg.sender,
            balanceOf(msg.sender),
            betai(msg.sender),
            alphai(msg.sender),
            Hholding(msg.sender),
            Sactivity(msg.sender)
        );
    }

    //Reward Calculator

    function RewardCalc() public view returns (uint256) {
        //components and multipliers
        uint256 TotalReward = totalRewardPool; //get from reward pool (Treward)
        uint256 Tokens = balanceOf(msg.sender); //total tokens held by users , what is the logic to calculate.
        uint256 Beta = betai(msg.sender); //betai
        uint256 Alpha = alphai(msg.sender); //alphai
        uint256 Sact = Sactivity(msg.sender); //Activity
        uint256 Hhol = Hholding(msg.sender); //holding

        uint256 R1 = Tokens * (1 + Beta - Alpha) * (1 + Hhol) * Sact;

        uint256 Reward = max(
            ((15 * 10 ** 2) * TotalReward),
            min(((999 * 10 ** 3) * TotalReward), (R1 / globalSummation))
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
            .transactionCount; // userTransactions count
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

    function getTokenDistribution(address _user) public view returns (uint256) {
        // this will return the values of Di / Dmax that is
        uint256 Di = balanceOf(_user);
        uint256 Dmax = maxTokenHolder;

        return (Di / Dmax); //check please
    }

    function betaMultiplier() public view returns (uint256) {
        // this will return the values of RewardPool / TargetRewardPool
        // rewardPool/totalRewardPool is total reward pool
        // targetRewardPool is some constant
        uint256 targetRewardPool = 1200; // some constant

        return (totalRewardPool / targetRewardPool);
    }

    function alphaMultiplier() public view returns (uint256) {
        // this will return the values of TargetActivity / TotalActivity
        uint256 TargetActivity = 600; // constant

        return (TargetActivity / totalTransactions); // check please
    }

    function updateUserContribution(
        address user,
        uint256 token,
        uint256 beta,
        uint256 alpha,
        uint256 H_holding,
        uint256 S_activity
    ) internal {
        // Step 1: Remove the old contribution
        globalSummation -= userContribution[user];

        // Step 2: Calculate the new contribution
        uint256 newContribution = token *
            (1 + beta - alpha) *
            (1 + H_holding) *
            S_activity;

        // Step 3: Update the user's contribution
        userContribution[user] = newContribution;

        // Step 4: Add the new contribution to the total
        globalSummation += newContribution;
    }
}
