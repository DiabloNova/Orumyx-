// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxDataStorage {

    // نقشه‌ای برای ذخیره ذخایر نفتی و طلای پشتیبانی شده
    mapping(address => uint256) public oilReserves; 
    mapping(address => uint256) public goldReserves; 

    // نقشه‌ای برای ذخیره تاریخچه ذخایر
    mapping(address => uint256[]) public oilReservesHistory;
    mapping(address => uint256[]) public goldReservesHistory;

    event OilReservesUpdated(address indexed updater, uint256 newAmount);
    event GoldReservesUpdated(address indexed updater, uint256 newAmount);

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can update reserves");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای به‌روزرسانی ذخایر نفتی
    function updateOilReserves(address to, uint256 amount) external onlyOwner {
        oilReserves[to] = amount;
        oilReservesHistory[to].push(amount);
        emit OilReservesUpdated(to, amount);
    }

    // تابع برای به‌روزرسانی ذخایر طلای
    function updateGoldReserves(address to, uint256 amount) external onlyOwner {
        goldReserves[to] = amount;
        goldReservesHistory[to].push(amount);
        emit GoldReservesUpdated(to, amount);
    }

    // تابع برای مشاهده تاریخچه ذخایر نفتی
    function getOilReservesHistory(address user) external view returns (uint256[] memory) {
        return oilReservesHistory[user];
    }

    // تابع برای مشاهده تاریخچه ذخایر طلای
    function getGoldReservesHistory(address user) external view returns (uint256[] memory) {
        return goldReservesHistory[user];
    }
}
