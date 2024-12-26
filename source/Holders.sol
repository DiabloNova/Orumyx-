mapping(address => uint256) public stakes;
uint256 public stakingRewardRate = 5;  // 5% reward rate

function stake(uint256 amount) external {
    require(orumyxToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    stakes[msg.sender] += amount;
}

function claimRewards() external {
    uint256 rewards = (stakes[msg.sender] * stakingRewardRate) / 100;
    orumyxToken.transfer(msg.sender, rewards);
}
