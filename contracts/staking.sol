// contracts/Staking.sol

pragma solidity ^0.8.0;

contract OrumyxStaking {
    // Address of the Orumyx token contract
    address public orumyxTokenAddress;

    // Mapping to store staked amounts for each user
    mapping(address => uint256) public stakedBalance;

    // Mapping to store staking rewards earned
    mapping(address => uint256) public earnedRewards;

    // Event for staking
    event Staked(address indexed staker, uint256 amount);

    // Event for claiming rewards
    event RewardsClaimed(address indexed user, uint256 amount);

    // Constructor to set the Orumyx token address
    constructor(address _orumyxTokenAddress) {
        orumyxTokenAddress = _orumyxTokenAddress;
    }

    // Function to stake tokens
    function stake(uint256 amount) public {
        require(IERC20(orumyxTokenAddress).balanceOf(msg.sender) >= amount, "Insufficient balance to stake");

        IERC20(orumyxTokenAddress).transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;

        emit Staked(msg.sender, amount);
    }

    // Function to unstake tokens
    function unstake(uint256 amount) public {
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");

        stakedBalance[msg.sender] -= amount;
        IERC20(orumyxTokenAddress).transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    // Function to claim staking rewards
    function claimRewards() public {
        uint256 rewards = earnedRewards[msg.sender];
        require(rewards > 0, "No rewards available to claim");

        earnedRewards[msg.sender] = 0;
        IERC20(orumyxTokenAddress).transfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    // Function to calculate and distribute staking rewards
    function distributeRewards() public {
        // Implementation of calculating and distributing rewards
        // ...
    }
}
