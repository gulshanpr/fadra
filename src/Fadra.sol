// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Fadra is ERC20 {
    uint256 public immutable maxSupply = 6_942_000_000 * 10 ** 18; // no need to hard code, we will get this value upon deployment
    uint256 private constant SECONDS_PER_YEAR = 31536000;
    uint256 private constant SECONDS_IN_THREE_MONTHS = 7776000;
    uint256 private constant SCALE = 1e18; // Minimum value with added precision

    uint256 TotalcalculatedReward; // needed for shortfall

    uint256 public totalRewardPool; // Tracks reward pool balance
    uint256 public maxTokenHolder = 0; // Maximum tokens held by a single user
    uint256 public contractTimestamp;

    address public rewardToken;
    address private lpWallet;
    address private marketingWallet;
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

    uint256 private constant BASE_BETA_MIN = 2e16; // Example: 0.02 * 1e18
    uint256 private constant BASE_BETA_MAX = 15e16; // Example: 0.15 * 1e18
    uint256 private constant BASE_ALPHA_MIN = 1e16; // Example: 0.01 * 1e18
    uint256 private constant BASE_ALPHA_MAX = 1e17; // Example: 0.1 * 1e18
    uint256 private constant TARGET_REWARD_POOL = 1200 * 1e18; // Example target
    uint256 private constant TARGET_ACTIVITY = 600; // Example activity target

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

    // minting function [transactions]
    // gotta remove the logic in mint function
    function mint(uint256 amount) public {
        
    }

    // transfer function [transaction]
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "Sender address cannot be zero");
        require(to != address(0), "Recipient address cannot be zero");
        require(amount > 0, "Transfer amount must be greater than zero");
        (
            uint256 LPfee,
            uint256 RPfee,
            uint256 marketingFee,
            uint256 afterFeeAmount
        ) = _calculateFees(amount);

        uint256 totalFee = LPfee + RPfee + marketingFee;

        require(
            IERC20(rewardToken).allowance(from, address(this)) >= totalFee,
            "Insufficient allowance for fees"
        );

        require(
            IERC20(rewardToken).transferFrom(from, address(this), totalFee),
            "Transfer failed"
        );

        totalRewardPool += RPfee;
        require(
            IERC20(rewardToken).transfer(lpWallet, LPfee),
            "Transfer to LP wallet failed"
        );
        require(
            IERC20(rewardToken).transfer(marketingWallet, marketingFee),
            "Transfer to Marketing wallet failed"
        );

        super._transfer(from, to, afterFeeAmount);

        uint256 reward = RewardCalc(from);
        TotalcalculatedReward = TotalcalculatedReward + reward;
        // 100 is just a placeholder value here
        // make another check in the if block i.e whether the reward is available in the pool or not ****imp****
        if ((reward > 100) && (balanceOf(address(this)) > 100)) {
            require(
                IERC20(rewardToken).transfer(from, reward),
                "Reward transfer failed"
            );
        } else {
            //shortfall : if the reward of user is not in the reward pool.
            //    uint256 RevisedReward = reward * (balanceOf(this)/TotalcalculatedReward); //idk how to check the value available in the contract [i tried]
            //    require(
            //             IERC20(rewardToken).transfer(from, RevisedReward),
            //             "Reward transfer failed"
            //         );

            // wrapped the above logic in this function
            shortfall(reward, from);
        }
        _updateUserActivity(from);
        _updateUserActivity(to);
        _updateMaxTokenHolder(from);
        _updateMaxTokenHolder(to);
    }

    //fee calculator
    function _calculateFees(
        uint256 amount
    )
        private
        pure
        returns (
            uint256 LPfee,
            uint256 RPfee,
            uint256 marketingFee,
            uint256 afterFeeAmount
        )
    {
        LPfee = (amount * 2) / 100; // 2%
        RPfee = (amount * 2) / 100; // 2%
        marketingFee = (amount * 85) / 10000; // 0.85%
        afterFeeAmount = amount - (LPfee + RPfee + marketingFee);
    }

    //reward calculator
    function RewardCalc(address _user) public returns (uint256) {
        uint256 Tokens = balanceOf(_user);
        uint256 Beta = betai(_user);
        uint256 Alpha = alphai(_user);
        uint256 Sact = Sactivity(_user);
        uint256 Hhol = Hholding(_user);

        uint256 numerator = Tokens * (1 + Beta - Alpha) * (1 + Hhol) * Sact;
        uint256 denominator = globalSummation;

        uint256 reward = max(
            (15 * totalRewardPool) / 100,
            min((999 * totalRewardPool) / 1000, numerator / denominator)
        );

        fallBack();
        return reward;
    }

    //helper functions and multipliers

    // in test check if some values are zero or doesn't exists what will happen (remove this afer test)

    function betai(address user) private view returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");
        uint256 tokenDistributionMultiplier = 1 - getTokenDistribution(user);
        uint256 betaMin = (BASE_BETA_MIN * totalRewardPool) /
            TARGET_REWARD_POOL;
        uint256 betaMax = (BASE_BETA_MAX * totalRewardPool) /
            TARGET_REWARD_POOL;
        return betaMin + (betaMax - betaMin) * tokenDistributionMultiplier;
    }

    function alphai(address user) private view returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");
        uint256 tokenDistributionMultiplier = getTokenDistribution(user);
        uint256 alphaMin = (BASE_ALPHA_MIN * TARGET_ACTIVITY) /
            totalTransactions;
        uint256 alphaMax = (BASE_ALPHA_MAX * TARGET_ACTIVITY) /
            totalTransactions;

        return alphaMin + (alphaMax - alphaMin) * tokenDistributionMultiplier;
    }

    function Hholding(address user) private view returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");
        uint256 lastTx = userActivities[user].lastTransactionTimestamp;
        uint256 timeDiff = block.timestamp - lastTx;
        uint256 activity = (timeDiff * SCALE) / SECONDS_PER_YEAR;
        return activity > SCALE ? SCALE : activity;
    }

    function Sactivity(address user) private view returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");
        uint256 userTxCount = userActivities[user].transactionCount;
        uint256 averageTx = totalTransactions / totalUsers;
        return (userTxCount * SCALE) / averageTx;
    }

    function fallBack() private returns (bool) {
        bool isThreeMonthPassed = ((block.timestamp - contractTimestamp) >=
            SECONDS_IN_THREE_MONTHS);
        if (isThreeMonthPassed && totalTransactions <= 1000) {
            // transfer all reward pool token to marketing wallet
            require(
                IERC20(rewardToken).transfer(marketingWallet, totalRewardPool),
                "Token transfer failed"
            );

            totalRewardPool = 0;
            return true;
        } else if (isThreeMonthPassed && totalTransactions > 1000) {
            contractTimestamp = block.timestamp;
            return false;
        } else {
            return false;
        }
    }

    function getTokenDistribution(address user) private view returns (uint256) {
        require(user != address(0), "Sender address cannot be zero");
        uint256 userTokens = balanceOf(user);
        return (userTokens * SCALE) / maxTokenHolder;
    }

    function _updateUserActivity(address user) private {
        require(user != address(0), "Sender address cannot be zero");
        if (userActivities[user].transactionCount == 0) {
            totalUsers++;
        }
        userActivities[user].transactionCount++;
        userActivities[user].lastTransactionTimestamp = block.timestamp;
    }

    function _updateMaxTokenHolder(address user) private {
        require(user != address(0), "Sender address cannot be zero");
        uint256 userHolding = balanceOf(user);
        if (userHolding > maxTokenHolder) {
            maxTokenHolder = userHolding;
        }
    }

    function updateUserContribution(address user) private {
        require(user != address(0), "Sender address cannot be zero");
        globalSummation -= userContribution[user];
        uint256 newContribution = balanceOf(user) *
            (1 + betai(user) - alphai(user)) *
            (1 + Hholding(user)) *
            Sactivity(user);
        userContribution[user] = newContribution;
        globalSummation += newContribution;
    }

    //shortfall function
    function shortfall(uint256 _reward, address rewardGainer) private {
        uint256 RevisedReward = _reward *
            (totalRewardPool / TotalcalculatedReward);
        require(
            IERC20(rewardToken).transfer(rewardGainer, RevisedReward),
            "Reward transfer failed"
        );
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}
