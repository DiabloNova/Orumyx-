// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SlashingMechanism {
    // State variables
    address public governance; // Governance address with slashing authority
    uint256 public totalStaked; // Total staked tokens in the contract

    struct Stake {
        uint256 amount;     // Amount of staked tokens
        uint256 timestamp;  // Time when the tokens were staked
    }

    mapping(address => Stake) public stakes; // Tracks stakes per user

    // ERC20 interface for token transfers
    IERC20 public orumyxToken;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Slashed(address indexed offender, uint256 amount);

    // Modifiers
    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can execute this");
        _;
    }

    modifier onlyStaker() {
        require(stakes[msg.sender].amount > 0, "No active stake found");
        _;
    }

    // Constructor to initialize governance and token contract
    constructor(address _governance, address _orumyxToken) {
        require(_governance != address(0), "Governance address cannot be zero");
        require(_orumyxToken != address(0), "Token address cannot be zero");
        governance = _governance;
        orumyxToken = IERC20(_orumyxToken);
    }

    // Function to stake tokens
    function stakeTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        orumyxToken.transferFrom(msg.sender, address(this), amount);

        if (stakes[msg.sender].amount > 0) {
            stakes[msg.sender].amount += amount;
        } else {
            stakes[msg.sender] = Stake(amount, block.timestamp);
        }

        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    // Function to unstake tokens
    function unstakeTokens(uint256 amount) external onlyStaker {
        require(stakes[msg.sender].amount >= amount, "Insufficient staked balance");

        stakes[msg.sender].amount -= amount;
        totalStaked -= amount;

        orumyxToken.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    // Governance function to slash tokens for misbehavior
    function slash(address offender, uint256 amount) external onlyGovernance {
        require(stakes[offender].amount >= amount, "Insufficient staked amount to slash");
        require(amount > 0, "Slashing amount must be greater than zero");

        // Deduct slashed amount
        stakes[offender].amount -= amount;
        totalStaked -= amount;

        // Transfer slashed tokens to governance or burn them
        orumyxToken.transfer(governance, amount);

        emit Slashed(offender, amount);
    }

    // Function to view stake details
    function getStake(address user) external view returns (uint256 amount, uint256 timestamp) {
        Stake memory stakeInfo = stakes[user];
        return (stakeInfo.amount, stakeInfo.timestamp);
    }

    // Function to update governance address (if compromised)
    function updateGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "New governance address cannot be zero");
        governance = newGovernance;
    }
}
