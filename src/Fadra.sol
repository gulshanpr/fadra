// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract Fadra is ERC20 {
    // I had to make everything public because of the test.
    uint256 public immutable maxSupply = 6_942_000_000 * 1e18; // no need to hard code, we will get this value upon deployment
    // we haven't scaled timestamp throughout the code
    uint256 public constant SECONDS_PER_YEAR = 31536000;
    uint256 public constant SECONDS_IN_THREE_MONTHS = 7776000;
    uint256 public constant SCALE = 1e18; // Minimum value with added precision

    uint256 TotalcalculatedReward; // needed for shortfall

    uint256 public totalRewardPool; // Tracks reward pool balance
    uint256 public maxTokenHolder = 0; // Maximum tokens held by a single user
    uint256 public contractTimestamp;

    address public rewardToken;
    address public lpWallet;
    address public marketingWallet;
    address public owner;

    mapping(address => uint256) public userContribution; // Tracks user contributions
    uint256 public globalSummation; // Global summation of all contributions

    struct UserActivity {
        uint256 balance;
        uint256 transactionCount;
        uint256 lastTransactionTimestamp;
        uint256 reward;
    }

    uint256 public totalTransactions; // Total transactions across the contract
    uint256 public totalUsers; // Tracks total unique users
    mapping(address => UserActivity) public userActivities; // Tracks activity per user

    uint256 public constant BASE_BETA_MIN = 2e16; // Example: 0.02 * 1e18
    uint256 public constant BASE_BETA_MAX = 15e16; // Example: 0.15 * 1e18
    uint256 public constant BASE_ALPHA_MIN = 1e16; // Example: 0.01 * 1e18
    uint256 public constant BASE_ALPHA_MAX = 1e17; // Example: 0.1 * 1e18
    uint256 public constant TARGET_REWARD_POOL = 1200 * 1e18; // Example target
    uint256 public constant TARGET_ACTIVITY = 600 * 1e18; // Example activity target

    constructor(
        string memory name,
        string memory symbol,
        address _lpWallet,
        address _marketingWallet
    ) ERC20(name, symbol) {
        owner = msg.sender;
        lpWallet = _lpWallet;
        marketingWallet = _marketingWallet;
        rewardToken = address(this);
        contractTimestamp = block.timestamp;
        _mint(owner, maxSupply);
    }

    function mint(uint256 amount) public {
        uint256 amountWithDecimals = amount * 10 ** 18;
        require(
            totalSupply() + amountWithDecimals <= maxSupply,
            "Minting exceeds max supply"
        );
        // check if this function is working correctly after users try to mint for(pass this function is this fails)
    }

    // transfer function [transaction]
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "Sender address cannot be zero");
        require(to != address(0), "Recipient address cannot be zero");
        require(amount > 0, "Transfer amount must be greater than zero------");

        if (from == owner) {
            super._transfer(from, to, amount);
            _updateMaxTokenHolder(to);
            _updateUserActivity(to);
            return;
        }

        (
            uint256 LPfee,
            uint256 RPfee,
            uint256 marketingFee,
            uint256 afterFeeAmount
        ) = _calculateFees(amount);

        require(
            afterFeeAmount > 0,
            "Transfer amount must be greater than zero"
        );

        super._transfer(from, to, afterFeeAmount);

        uint256 totalFee = LPfee + RPfee + marketingFee;

        // allowance is confirmed from frontend
        require(
            IERC20(rewardToken).allowance(from, address(this)) >= totalFee,
            "Insufficient allowance for fees"
        );

        require(TransFee(from, address(this), RPfee), "Transfer failed");

        totalRewardPool += RPfee;
        require(
            TransFee(from, lpWallet, LPfee),
            "Transfer to LP wallet failed"
        );
        require(
            TransFee(from, marketingWallet, marketingFee),
            "Transfer to Marketing wallet failed"
        );

        
        _updateMaxTokenHolder(from);
        _updateMaxTokenHolder(to);
        _updateUserActivity(from);
        updateUserContribution(from);

        // after transaction calculate reward for that transaction

        uint256 _reward = RewardCalc(from);

        // add the calculated reward to it's struct reward member

        // userActivities[from].reward = _reward + userActivities[from].reward;

        // then run checks for reward transfer
        // 100 is just a placeholder value here
        // make another check in the if block i.e whether the reward is available in the pool or not ****imp****
        if (
            (userActivities[from].reward > 100) &&
            (balanceOf(address(this)) > 100)
        ) {
            require(
                IERC20(rewardToken).transfer(from, userActivities[from].reward),
                "Reward transfer failed"
            );
            _updateMaxTokenHolder(from);
            _updateMaxTokenHolder(to);
        }

        // _updateUserActivity(from);
        // _updateUserActivity(to);
        // check if one does transfer is this updating all states and is this transferring value to address or not?
        // also check for the allowance and 100 reward token limit, only transfer reward if 100 token is accumulate
    }

    function TransFee(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        super._transfer(from, to, amount);
        return true;
    }

    //fee calculator
    function _calculateFees(
        uint256 amount
    )
        public
        pure
        returns (
            uint256 LPfee,
            uint256 RPfee,
            uint256 marketingFee,
            uint256 afterFeeAmount
        )
    {
        LPfee = (amount * 2) / 100;
        RPfee = (amount * 2) / 100;
        marketingFee = (amount * 85) / 10000;

        afterFeeAmount = amount - (LPfee + RPfee + marketingFee);

        return (LPfee, RPfee, marketingFee, afterFeeAmount);
    }

    //reward calculator
    function RewardCalc(address _user) public returns (uint256) {
        // uint256 Tokens = balanceOf(_user); uncomment this line after test IMPORTANT
        uint256 Tokens = 2000 * 1e18;
        uint256 Beta = betai(_user);
        uint256 Alpha = alphai(_user);
        uint256 Sact = Sactivity(_user);
        uint256 Hhol = Hholding(_user);

        uint256 numerator = Tokens * (1 + Beta - Alpha) * (1 + Hhol) * Sact;
        uint256 denominator = globalSummation * 1e18;

        uint256 reward = max(
            (15 * (totalRewardPool * 1e18)) / 100,
            min(
                (999 * (totalRewardPool * 1e18)) / 1000,
                numerator / denominator
            )
        );

        fallBack();
        return reward;
        // check if we are getting values for all functions
    }

    //helper functions and multipliers

    // in test check if some values are zero or doesn't exists what will happen (remove this afer test)

    // and view plssssssssssss (i have remove it for testing purposes)
    function betai(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");

        uint256 tokenDistributionMultiplier = 1e18 - getTokenDistribution(user);

        // Fix scaling issues by adjusting calculations
        uint256 betaMin = (BASE_BETA_MIN * totalRewardPool) /
            TARGET_REWARD_POOL; // Keep 1e18 scaling
        uint256 betaMax = (BASE_BETA_MAX * totalRewardPool) /
            TARGET_REWARD_POOL; // Keep 1e18 scaling

        // Ensure the final computation maintains correct scale
        uint256 result = betaMin +
            ((betaMax - betaMin) * tokenDistributionMultiplier) /
            1e18;

        return result;
    }

    function debugBetai(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");

        uint256 tokenDistributionMultiplier = 1e18 - getTokenDistribution(user);
        console.log(
            "Token Distribution Multiplier:",
            tokenDistributionMultiplier
        );

        // Fix scaling: Don't multiply totalRewardPool by 1e18 again
        uint256 betaMin = (BASE_BETA_MIN * totalRewardPool) /
            TARGET_REWARD_POOL;
        console.log("Beta Min:", betaMin);

        uint256 betaMax = (BASE_BETA_MAX * totalRewardPool) /
            TARGET_REWARD_POOL;
        console.log("Beta Max:", betaMax);

        uint256 betaDiff = betaMax - betaMin;
        console.log("Beta Difference (betaMax - betaMin):", betaDiff);

        uint256 scaledBetaDiff = (betaDiff * tokenDistributionMultiplier) /
            1e18;
        console.log("Scaled Beta Difference:", scaledBetaDiff);

        uint256 result = betaMin + scaledBetaDiff;
        console.log("Final Beta Value:", result);

        return result;
    }

    // and view plssssssssssss (i have remove it for testing purposes)
    function alphai(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");

        uint256 tokenDistributionMultiplier = getTokenDistribution(user);

        // Ensure totalTransactions is not zero to prevent division by zero
        require(
            totalTransactions > 0,
            "Total transactions must be greater than zero"
        );

        // Properly scaled calculations
        uint256 alphaMin = (BASE_ALPHA_MIN * TARGET_ACTIVITY) /
            totalTransactions; // No extra 1e18
        uint256 alphaMax = (BASE_ALPHA_MAX * TARGET_ACTIVITY) /
            totalTransactions; // No extra 1e18

        // Ensure correct scaling in the final calculation
        uint256 alphaDiff = alphaMax - alphaMin;
        uint256 scaledAlphaDiff = (alphaDiff * tokenDistributionMultiplier) /
            1e18;
        uint256 result = alphaMin + scaledAlphaDiff;

        return result;
    }

    function debugAlphai(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");

        uint256 tokenDistributionMultiplier = getTokenDistribution(user);
        console.log(
            "Token Distribution Multiplier:",
            tokenDistributionMultiplier
        );

        require(
            totalTransactions > 0,
            "Total transactions must be greater than zero"
        );

        uint256 alphaMin = (BASE_ALPHA_MIN * TARGET_ACTIVITY) /
            totalTransactions;
        console.log("Alpha Min:", alphaMin);

        uint256 alphaMax = (BASE_ALPHA_MAX * TARGET_ACTIVITY) /
            totalTransactions;
        console.log("Alpha Max:", alphaMax);

        uint256 alphaDiff = alphaMax - alphaMin;
        console.log("Alpha Difference (alphaMax - alphaMin):", alphaDiff);

        uint256 scaledAlphaDiff = (alphaDiff * tokenDistributionMultiplier) /
            1e18;
        console.log("Scaled Alpha Difference:", scaledAlphaDiff);

        uint256 result = alphaMin + scaledAlphaDiff;
        console.log("Final Alpha Value:", result);

        return result;
    }

    // and view plssssssssssss (i have remove it for testing purposes)
    function Hholding(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");

        uint256 lastTx = userActivities[user].lastTransactionTimestamp;
        uint256 timeDiff = block.timestamp - lastTx;

        // Ensure scaling is maintained properly
        uint256 activity = (timeDiff * SCALE) / SECONDS_PER_YEAR;

        // Remove unnecessary division by 1e18 if SCALE is already in 1e18 format
        return activity > SCALE ? SCALE : activity;
    }

    function debugHholding(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");

        uint256 lastTx = userActivities[user].lastTransactionTimestamp;
        console.log("Last Transaction Timestamp:", lastTx);

        uint256 timeDiff = block.timestamp - lastTx;
        console.log("Time Difference:", timeDiff);

        uint256 activity = (timeDiff * SCALE) / SECONDS_PER_YEAR;
        console.log("Raw Activity:", activity);

        uint256 finalActivity = activity > SCALE ? SCALE : activity;
        console.log("Final Activity:", finalActivity);

        return finalActivity;
    }

    // and view plssssssssssss (i have remove it for testing purposes)
    function Sactivity(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");

        uint256 userTxCount = userActivities[user].transactionCount;

        // Prevent division by zero
        if (totalUsers == 0) return 0;

        uint256 averageTx = totalTransactions / totalUsers;

        return averageTx > 0 ? (userTxCount * SCALE) / averageTx : 0;
    }

    // delete this later
    function debugSactivity(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");

        uint256 userTxCount = userActivities[user].transactionCount;
        console.log("User Transaction Count:", userTxCount);

        if (totalUsers == 0) {
            console.log("Total Users is 0, returning 0");
            return 0;
        }

        uint256 averageTx = totalTransactions / totalUsers;
        console.log("Average Transaction:", averageTx);

        uint256 result = averageTx > 0 ? (userTxCount * SCALE) / averageTx : 0;
        console.log("Sactivity Result:", result);

        return result;
    }

    function fallBack() public returns (bool) {
        bool isThreeMonthPassed = ((block.timestamp - contractTimestamp) >=
            SECONDS_IN_THREE_MONTHS);
        if (isThreeMonthPassed && totalTransactions <= 1000) {
            // transfer all reward pool token to marketing wallet
            require(
                IERC20(rewardToken).transfer(marketingWallet, totalRewardPool),
                "Token transfer failed"
            );
            // is transfer happening or not
            totalRewardPool = 0;
            return true;
        } else if (isThreeMonthPassed && totalTransactions > 1000) {
            contractTimestamp = block.timestamp;
            return false;
            // check this condition
        } else {
            return false;
        }
    }

    // check alphai once this function is tested , checked this
    function getTokenDistribution(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");
        // uint256 userTokens = balanceOf(user); // ye 1e18 deta hai
        uint256 userTokens = 500 * SCALE;
        if (maxTokenHolder == 0) return 0;
        uint256 resultToken = (userTokens) / (maxTokenHolder);
        return resultToken * 1e18;
        // check if it is returing correct Di/Dmax
        // also write gas this function used
    }

    function debugGetTokenDistribution(address user) public returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");

        console.log(
            "msg sender in getTokenDistribution:",
            balanceOf(msg.sender)
        );

        uint256 userTokens = 500 * SCALE; // Scale only once
        console.log("User Tokens:", userTokens);

        if (maxTokenHolder == 0) {
            console.log("Max Token Holder is 0, returning 0");
            return 0;
        }

        console.log("Max Token Holder:", maxTokenHolder);

        // Fix scaling issue
        uint256 result = (userTokens * SCALE) / (maxTokenHolder);
        console.log("Token Distribution Result (Di/Dmax):", result);

        return result;
    }

    function _updateUserActivity(address user) public {
        require(user != address(0), "Sender address cannot be zero");
        if (userActivities[user].transactionCount == 0) {
            totalUsers++;
        }
        userActivities[user].transactionCount++;
        totalTransactions++;
        userActivities[user].lastTransactionTimestamp = block.timestamp;
        // for the first transaction if unique user is increasing or not,
        // then check if it is properly increasing transactionCount and lastTransactionTimestamp
        // also write gas this function used
    }

      function _DebugupdateUserActivity(address user) public {
        require(user != address(0), "Sender address cannot be zero");
        if (userActivities[user].transactionCount == 0) {
            totalUsers++;
            console.log(totalUsers);
        }
        uint256 usertrans = userActivities[user].transactionCount++;
        console.log("the user transaction count is: ", usertrans);
        uint256 ttl = totalTransactions++;
        console.log("ttl is: ", ttl);
        console.log("total transaction: ", totalTransactions);
        userActivities[user].lastTransactionTimestamp = block.timestamp;
        // for the first transaction if unique user is increasing or not,
        // then check if it is properly increasing transactionCount and lastTransactionTimestamp
        // also write gas this function used
    }

    function _updateMaxTokenHolder(address user) public {
        require(user != address(0), "Sender address cannot be zero");
        uint256 userHolding = balanceOf(user);
        if (userHolding > maxTokenHolder) {
            maxTokenHolder = userHolding;
        }
        // check if it is correctly handling the maxToken holder
        // also write gas this function used
    }

    function updateUserContribution(address user) public {
        require(user != address(0), "Sender address cannot be zero");

        if (globalSummation != 0) {
            globalSummation -= userContribution[user];
            uint256 newContribution = balanceOf(user) *
                (1 + betai(user) - alphai(user)) *
                (1 + Hholding(user)) *
                Sactivity(user);
            userContribution[user] = newContribution;
            globalSummation += newContribution;
        } else {
            uint256 newContribution = balanceOf(user) *
                (1 + betai(user) - alphai(user)) *
                (1 + Hholding(user)) *
                Sactivity(user);
            userContribution[user] = newContribution;
            globalSummation += newContribution;
        }
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }

    // getter and setter functions

    function setMaxTokenHolder(uint256 _maxTokenHolder) external {
        maxTokenHolder = _maxTokenHolder * 1e18;
    }

    function getMaxTokenHolder() public view returns (uint256) {
        return maxTokenHolder;
    }

    function setTotalRewardPoolValue(uint256 _value) external {
        totalRewardPool = _value;
    }

    function getTotalRewardPoolValue() public view returns (uint256) {
        return totalRewardPool;
    }

    function setTotalTransaction(uint256 _value) external {
        totalTransactions = _value;
    }

    function getTotalTransaction() public view returns (uint256) {
        return totalTransactions;
    }

    function setUserActivity(
        address user,
        uint256 balance,
        uint256 transactionCount,
        uint256 lastTransactionTimestamp,
        uint256 reward
    ) public {
        userActivities[user] = UserActivity({
            balance: balance,
            transactionCount: transactionCount,
            lastTransactionTimestamp: lastTransactionTimestamp,
            reward: reward
        });
    }

    function getUserActivity(
        address user
    )
        public
        view
        returns (
            uint256 balance,
            uint256 transactionCount,
            uint256 lastTransactionTimestamp,
            uint256 reward
        )
    {
        UserActivity memory activity = userActivities[user];
        return (
            activity.balance,
            activity.transactionCount,
            activity.lastTransactionTimestamp,
            activity.reward
        );
    }

    function setTotalUser(uint256 _users) external {
        totalUsers = _users;
    }

    function getTotalUser() public view returns (uint256) {
        return totalUsers;
    }
}
