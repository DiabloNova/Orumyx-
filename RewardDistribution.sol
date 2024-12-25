// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxRewardAndCompensation {

    address public owner;
    uint256 public totalInvestment;
    mapping(address => uint256) public investorBalances;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public compensation;

    event InvestmentReceived(address indexed investor, uint256 amount);
    event RewardDistributed(address indexed investor, uint256 amount);
    event CompensationDistributed(address indexed investor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier hasInvestment(address investor) {
        require(investorBalances[investor] > 0, "No investment found for this address");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalInvestment = 0;
    }

    // تابع برای دریافت سرمایه گذاری
    function invest() external payable {
        require(msg.value > 0, "Investment must be greater than zero");
        investorBalances[msg.sender] += msg.value;
        totalInvestment += msg.value;
        emit InvestmentReceived(msg.sender, msg.value);
    }

    // تابع برای توزیع پاداش به سرمایه گذاران
    function distributeRewards() external onlyOwner {
        for (address investor = address(0); investor < address(2**160-1); investor++) {
            uint256 rewardAmount = calculateReward(investor);
            rewards[investor] += rewardAmount;
            payable(investor).transfer(rewardAmount);
            emit RewardDistributed(investor, rewardAmount);
        }
    }

    // تابع برای محاسبه پاداش برای هر سرمایه گذار
    function calculateReward(address investor) internal view returns (uint256) {
        uint256 investmentPercentage = (investorBalances[investor] * 100) / totalInvestment;
        uint256 reward = (address(this).balance * investmentPercentage) / 100;
        return reward;
    }

    // تابع برای توزیع جبران خسارت به سرمایه گذاران
    function distributeCompensation(address investor) external onlyOwner hasInvestment(investor) {
        uint256 compensationAmount = calculateCompensation(investor);
        compensation[investor] += compensationAmount;
        payable(investor).transfer(compensationAmount);
        emit CompensationDistributed(investor, compensationAmount);
    }

    // تابع برای محاسبه جبران خسارت برای هر سرمایه گذار
    function calculateCompensation(address investor) internal view returns (uint256) {
        uint256 compensationAmount = (investorBalances[investor] * 10) / 100; // مثال: 10% جبران خسارت
        return compensationAmount;
    }

    // تابع برای مشاهده پاداش سرمایه گذار
    function getReward(address investor) external view returns (uint256) {
        return rewards[investor];
    }

    // تابع برای مشاهده جبران خسارت سرمایه گذار
    function getCompensation(address investor) external view returns (uint256) {
        return compensation[investor];
    }
}
