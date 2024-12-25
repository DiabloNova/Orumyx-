// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxLiquidity {

    address public owner;
    mapping(address => uint256) public liquidityProviders;  // ذخیره‌سازی نقدینگی تامین شده توسط هر فرد
    mapping(address => uint256) public liquidityBalances;   // ذخیره‌سازی موجودی هر فرد در استخر
    uint256 public totalLiquidity;  // مجموع نقدینگی موجود در استخر
    uint256 public totalShares;     // مجموع سهم‌ها (LP tokens) در استخر

    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای افزودن نقدینگی به استخر
    function addLiquidity() external payable {
        require(msg.value > 0, "Amount must be greater than zero");

        // محاسبه سهم جدید
        uint256 sharesIssued = 0;
        if (totalLiquidity == 0) {
            sharesIssued = msg.value;  // اگر استخر خالی است، هر فرد سهم مساوی دریافت می‌کند
        } else {
            sharesIssued = msg.value * totalShares / totalLiquidity;  // محاسبه سهم بر اساس نقدینگی موجود
        }

        liquidityProviders[msg.sender] += msg.value;
        liquidityBalances[msg.sender] += sharesIssued;
        totalLiquidity += msg.value;
        totalShares += sharesIssued;

        emit LiquidityAdded(msg.sender, msg.value);
    }

    // تابع برای برداشت نقدینگی از استخر
    function removeLiquidity(uint256 sharesToRemove) external {
        require(sharesToRemove > 0, "Shares to remove must be greater than zero");
        require(liquidityBalances[msg.sender] >= sharesToRemove, "Insufficient balance");

        uint256 amountToWithdraw = sharesToRemove * totalLiquidity / totalShares;

        liquidityProviders[msg.sender] -= amountToWithdraw;
        liquidityBalances[msg.sender] -= sharesToRemove;
        totalLiquidity -= amountToWithdraw;
        totalShares -= sharesToRemove;

        payable(msg.sender).transfer(amountToWithdraw);

        emit LiquidityRemoved(msg.sender, amountToWithdraw);
    }

    // تابع برای مشاهده موجودی نقدینگی کاربر در استخر
    function getLiquidityBalance(address provider) external view returns (uint256) {
        return liquidityBalances[provider];
    }

    // تابع برای مشاهده نقدینگی کل استخر
    function getTotalLiquidity() external view returns (uint256) {
        return totalLiquidity;
    }

    // تابع برای مشاهده سهم‌های کل استخر
    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }
}
