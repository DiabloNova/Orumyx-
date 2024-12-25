// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxRewards {

    address public owner;
    uint256 public rewardRate;  // نرخ پاداش برای سرمایه‌گذاران
    mapping(address => uint256) public investments;  // نقشه‌ای برای ذخیره میزان سرمایه‌گذاری هر کاربر
    mapping(address => uint256) public rewards;  // نقشه‌ای برای ذخیره پاداش‌های تعلق گرفته به هر کاربر
    uint256 public totalInvestments;  // مجموع سرمایه‌گذاری‌ها

    event InvestmentMade(address indexed investor, uint256 amount);
    event RewardClaimed(address indexed investor, uint256 rewardAmount);
    event CompensationIssued(address indexed investor, uint256 compensationAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can modify reward rate");
        _;
    }

    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    // تابع برای سرمایه‌گذاری
    function invest() external payable {
        require(msg.value > 0, "Investment must be greater than zero");

        investments[msg.sender] += msg.value;
        totalInvestments += msg.value;

        // محاسبه و اختصاص پاداش
        uint256 reward = calculateReward(msg.value);
        rewards[msg.sender] += reward;

        emit InvestmentMade(msg.sender, msg.value);
    }

    // تابع برای محاسبه پاداش به ازای سرمایه‌گذاری
    function calculateReward(uint256 investmentAmount) public view returns (uint256) {
        return investmentAmount * rewardRate / 100;
    }

    // تابع برای دریافت پاداش
    function claimReward() external {
        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount > 0, "No reward available");

        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(rewardAmount);

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    // تابع برای پرداخت جبران خسارت
    function issueCompensation(address investor, uint256 compensationAmount) external onlyOwner {
        require(investments[investor] > 0, "Investor must have made an investment");

        payable(investor).transfer(compensationAmount);

        emit CompensationIssued(investor, compensationAmount);
    }

    // تابع برای مشاهده میزان سرمایه‌گذاری هر کاربر
    function getInvestmentAmount(address investor) external view returns (uint256) {
        return investments[investor];
    }

    // تابع برای مشاهده میزان پاداش هر کاربر
    function getRewardAmount(address investor) external view returns (uint256) {
        return rewards[investor];
    }
}
