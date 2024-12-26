// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimal ERC20 Interface for ORX Token
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract RewardPoolManagement {
    // Governance and Token
    address public governance;
    IERC20 public orumyxToken;

    // Reward Pool Details
    uint256 public totalRewards; // Total available rewards in the pool
    uint256 public rewardRate; // Reward rate (tokens distributed per second)
    uint256 public lastUpdateTime; // Last time rewards were distributed
    uint256 public rewardPerTokenStored; // Accumulated rewards per token
    uint256 public totalStaked; // Total staked tokens

    // Staking and Rewards
    mapping(address => uint256) public userStakes; // Staked amounts by user
    mapping(address => uint256) public userRewards; // User rewards
    mapping(address => uint256) public userRewardPerTokenPaid; // Rewards already claimed

    // Events
    event RewardAdded(uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event GovernanceUpdated(address newGovernance);

    // Modifiers
    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can execute this");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            userRewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // Constructor
    constructor(address _governance, address _orumyxToken, uint256 _rewardRate) {
        require(_governance != address(0), "Invalid governance address");
        require(_orumyxToken != address(0), "Invalid token address");
        require(_rewardRate > 0, "Reward rate must be greater than zero");

        governance = _governance;
        orumyxToken = IERC20(_orumyxToken);
        rewardRate = _rewardRate;
    }

    // Stake ORX tokens
    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        userStakes[msg.sender] += amount;
        totalStaked += amount;

        orumyxToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // Withdraw staked tokens
    function withdraw(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(userStakes[msg.sender] >= amount, "Insufficient stake");

        userStakes[msg.sender] -= amount;
        totalStaked -= amount;

        orumyxToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    // Claim earned rewards
    function claimReward() external updateReward(msg.sender) {
        uint256 reward = userRewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        userRewards[msg.sender] = 0;
        orumyxToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    // Add rewards to the pool (funded by governance)
    function addReward(uint256 amount) external onlyGovernance {
        require(amount > 0, "Reward amount must be greater than zero");

        totalRewards += amount;
        orumyxToken.transferFrom(msg.sender, address(this), amount);

        emit RewardAdded(amount);
    }

    // Update governance address
    function updateGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "Invalid governance address");
        governance = newGovernance;
        emit GovernanceUpdated(newGovernance);
    }

    // Calculate reward per token
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalStaked;
    }

    // Calculate earned rewards for a user
    function earned(address account) public view returns (uint256) {
        return
            ((userStakes[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            userRewards[account];
    }

    // Get staked balance of a user
    function stakedBalance(address account) external view returns (uint256) {
        return userStakes[account];
    }

    // Get total rewards in the pool
    function getTotalRewards() external view returns (uint256) {
        return totalRewards;
    }
}
