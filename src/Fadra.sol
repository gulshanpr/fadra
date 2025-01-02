// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Fadra is ERC20 {
    uint256 public immutable maxSupply = 6_942_000_000 * 10 ** 18;
    uint256 private constant SECONDS_PER_YEAR = 31536000;
    uint256 private constant SCALE = 1e18; // Minimum value with added precision

    uint256 public totalRewardPool; // Tracks reward pool balance
    uint256 public maxTokenHolder = 0; // Maximum tokens held by a single user

    address public rewardToken;
    address public lpWallet;
    address public marketingWallet;

    mapping(address => uint256) public userContribution; // Tracks user contributions
    uint256 public globalSummation; // Global summation of all contributions

    struct UserActivity {
        uint256 balance;
        uint256 transactionCount;
        uint256 lastTransactionTimestamp;
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
        lpWallet = _lpWallet;
        marketingWallet = _marketingWallet;
        rewardToken = address(this);
    }

    function mint(uint256 amount) public {
        uint256 amountWithDecimals = amount * 10 ** 18;
        require(
            totalSupply() + amountWithDecimals <= maxSupply,
            "Minting exceeds max supply"
        );

        (
            uint256 LPfee,
            uint256 RPfee,
            uint256 marketingFee,
            uint256 afterFeeAmount
        ) = _calculateFees(amountWithDecimals);

        _mint(msg.sender, afterFeeAmount);
        totalRewardPool += RPfee;

        IERC20(rewardToken).transfer(lpWallet, LPfee);
        IERC20(rewardToken).transfer(marketingWallet, marketingFee);

        _updateUserActivity(msg.sender);
        _updateMaxTokenHolder(msg.sender);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        (
            uint256 LPfee,
            uint256 RPfee,
            uint256 marketingFee,
            uint256 afterFeeAmount
        ) = _calculateFees(amount);

        IERC20(rewardToken).transferFrom(
            from,
            address(this),
            LPfee + RPfee + marketingFee
        );
        totalRewardPool += RPfee;

        IERC20(rewardToken).transfer(lpWallet, LPfee);
        IERC20(rewardToken).transfer(marketingWallet, marketingFee);

        super._transfer(from, to, afterFeeAmount);

        _updateUserActivity(from);
        _updateUserActivity(to);
        _updateMaxTokenHolder(from);
        _updateMaxTokenHolder(to);
    }

    function _calculateFees(
        uint256 amount
    )
        internal
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

    function RewardCalc() public view returns (uint256) {
        uint256 Tokens = balanceOf(msg.sender);
        uint256 Beta = betai(msg.sender);
        uint256 Alpha = alphai(msg.sender);
        uint256 Sact = Sactivity(msg.sender);
        uint256 Hhol = Hholding(msg.sender);

        uint256 numerator = Tokens * (1 + Beta - Alpha) * (1 + Hhol) * Sact;
        uint256 denominator = globalSummation;

        uint256 reward = max(
            (15 * totalRewardPool) / 100,
            min((999 * totalRewardPool) / 1000, numerator / denominator)
        );

        return reward;
    }

    function betai(address user) public view returns (uint256) {
        uint256 tokenDistributionMultiplier = 1 - getTokenDistribution(user);
        uint256 betaMin = (BASE_BETA_MIN * totalRewardPool) /
            TARGET_REWARD_POOL;
        uint256 betaMax = (BASE_BETA_MAX * totalRewardPool) /
            TARGET_REWARD_POOL;
        return betaMin + (betaMax - betaMin) * tokenDistributionMultiplier;
    }

    function alphai(address user) public view returns (uint256) {
        uint256 tokenDistributionMultiplier = getTokenDistribution(user);
        uint256 alphaMin = (BASE_ALPHA_MIN * TARGET_ACTIVITY) /
            totalTransactions;
        uint256 alphaMax = (BASE_ALPHA_MAX * TARGET_ACTIVITY) /
            totalTransactions;
        return alphaMin + (alphaMax - alphaMin) * tokenDistributionMultiplier;
    }

    function Hholding(address user) public view returns (uint256) {
        uint256 lastTx = userActivities[user].lastTransactionTimestamp;
        uint256 timeDiff = block.timestamp - lastTx;
        uint256 activity = (timeDiff * SCALE) / SECONDS_PER_YEAR;
        return activity > SCALE ? SCALE : activity;
    }

    function Sactivity(address user) public view returns (uint256) {
        uint256 userTxCount = userActivities[user].transactionCount;
        uint256 averageTx = totalTransactions / totalUsers;
        return (userTxCount * SCALE) / averageTx;
    }

    function getTokenDistribution(address user) public view returns (uint256) {
        uint256 userTokens = balanceOf(user);
        return (userTokens * SCALE) / maxTokenHolder;
    }

    function _updateUserActivity(address user) internal {
        if (userActivities[user].transactionCount == 0) {
            totalUsers++;
        }
        userActivities[user].transactionCount++;
        userActivities[user].lastTransactionTimestamp = block.timestamp;
    }

    function _updateMaxTokenHolder(address user) internal {
        uint256 userHolding = balanceOf(user);
        if (userHolding > maxTokenHolder) {
            maxTokenHolder = userHolding;
        }
    }

    function updateUserContribution(address user) internal {
        globalSummation -= userContribution[user];
        uint256 newContribution = balanceOf(user) *
            (1 + betai(user) - alphai(user)) *
            (1 + Hholding(user)) *
            Sactivity(user);
        userContribution[user] = newContribution;
        globalSummation += newContribution;
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? a : b;
    }
}
