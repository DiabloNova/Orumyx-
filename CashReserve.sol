// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxCashReserve {

    address public owner;
    uint256 public reserveBalance;  // موجودی ذخیره نقدی
    mapping(address => uint256) public userBalances;  // موجودی هر کاربر

    event DepositToReserve(address indexed depositor, uint256 amount);
    event WithdrawFromReserve(address indexed withdrawer, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier hasSufficientBalance(uint256 amount) {
        require(reserveBalance >= amount, "Insufficient reserve balance");
        _;
    }

    constructor() {
        owner = msg.sender;
        reserveBalance = 0;
    }

    // تابع برای واریز نقدی به ذخیره
    function depositToReserve() external payable onlyOwner {
        require(msg.value > 0, "Amount must be greater than zero");
        reserveBalance += msg.value;
        emit DepositToReserve(msg.sender, msg.value);
    }

    // تابع برای برداشت از ذخیره نقدی
    function withdrawFromReserve(uint256 amount) external onlyOwner hasSufficientBalance(amount) {
        reserveBalance -= amount;
        payable(msg.sender).transfer(amount);
        emit WithdrawFromReserve(msg.sender, amount);
    }

    // تابع برای واریز ارز به حساب کاربری
    function deposit() external payable {
        require(msg.value > 0, "Amount must be greater than zero");
        userBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // تابع برای برداشت از حساب کاربری (مستقیم از ذخیره نقدی)
    function withdraw(uint256 amount) external hasSufficientBalance(amount) {
        require(userBalances[msg.sender] >= amount, "Insufficient user balance");
        userBalances[msg.sender] -= amount;
        reserveBalance -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // تابع برای مشاهده موجودی ذخیره نقدی
    function getReserveBalance() external view returns (uint256) {
        return reserveBalance;
    }

    // تابع برای مشاهده موجودی کاربر
    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }
}
