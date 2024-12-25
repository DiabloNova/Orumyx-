// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxCurrencyReserve {

    address public owner;
    uint256 public reserveBalance;  // موجودی ذخیره
    uint256 public exchangeRate;  // نرخ ارز
    uint256 public minimumExchangeRate;  // حداقل نرخ ارز
    uint256 public maximumExchangeRate;  // حداکثر نرخ ارز
    mapping(address => uint256) public userBalances;

    event ReserveBalanceUpdated(uint256 newReserveBalance);
    event ExchangeRateUpdated(uint256 newExchangeRate);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier hasSufficientReserve(uint256 amount) {
        require(reserveBalance >= amount, "Insufficient reserve balance");
        _;
    }

    constructor(uint256 _initialExchangeRate, uint256 _minimumExchangeRate, uint256 _maximumExchangeRate) {
        owner = msg.sender;
        reserveBalance = 0;
        exchangeRate = _initialExchangeRate;
        minimumExchangeRate = _minimumExchangeRate;
        maximumExchangeRate = _maximumExchangeRate;
    }

    // تابع برای واریز به ذخیره ارز
    function deposit() external payable {
        require(msg.value > 0, "Amount must be greater than zero");
        reserveBalance += msg.value;
        userBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // تابع برای برداشت از ذخیره ارز
    function withdraw(uint256 amount) external hasSufficientReserve(amount) {
        require(userBalances[msg.sender] >= amount, "Insufficient user balance");
        userBalances[msg.sender] -= amount;
        reserveBalance -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // تابع برای به‌روزرسانی نرخ ارز
    function updateExchangeRate(uint256 newRate) external onlyOwner {
        require(newRate >= minimumExchangeRate, "New rate is lower than the minimum allowed");
        require(newRate <= maximumExchangeRate, "New rate is higher than the maximum allowed");
        exchangeRate = newRate;
        emit ExchangeRateUpdated(newRate);
    }

    // تابع برای مشاهده نرخ ارز
    function getExchangeRate() external view returns (uint256) {
        return exchangeRate;
    }

    // تابع برای مشاهده موجودی ذخیره
    function getReserveBalance() external view returns (uint256) {
        return reserveBalance;
    }

    // تابع برای مشاهده موجودی کاربر
    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }
}
