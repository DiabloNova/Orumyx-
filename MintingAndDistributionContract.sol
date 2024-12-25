// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Orumyx {
    string public name = "Orumyx";               // نام توکن
    string public symbol = "OMX";                 // نماد توکن
    uint8 public decimals = 18;                   // تعداد اعشار توکن
    uint256 public totalSupply;                   // مقدار کل توکن‌ها
    address public owner;                         // آدرس مالک (خالق قرارداد)
    address public reserveAddress;                // آدرس ذخایر (برای پشتوانه)
    
    mapping(address => uint256) public balanceOf;             // نگهداری موجودی‌ها
    mapping(address => mapping(address => uint256)) public allowance; // نگهداری مجوزها برای transferFrom
    
    event Transfer(address indexed from, address indexed to, uint256 value);  // رویداد انتقال توکن
    event Approval(address indexed owner, address indexed spender, uint256 value);  // رویداد تایید مجوز
    event TokensMinted(address indexed to, uint256 amount);   // رویداد تولید توکن جدید

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0), "Invalid recipient address");
        _;
    }

    // contract creator
    constructor(address _reserveAddress) {
        owner = msg.sender;                            // قرارداد توسط خالق خود مستقر می‌شود
        reserveAddress = _reserveAddress;              // آدرس ذخایر تنظیم می‌شود
        totalSupply = 1000000 * (10 ** uint256(decimals)); // مقدار اولیه توکن‌ها
        balanceOf[owner] = totalSupply;                // توکن‌ها به آدرس مالک منتقل می‌شود
        emit Transfer(address(0), owner, totalSupply);  // اعلام تولید اولیه توکن‌ها
    }

    // token generation function (Mint)
    function mint(address to, uint256 amount) external onlyOwner validRecipient(to) {
        totalSupply += amount;                          // مقدار کل توکن‌ها افزایش می‌یابد
        balanceOf[to] += amount;                        // توکن‌های جدید به آدرس مقصد افزوده می‌شود
        emit TokensMinted(to, amount);                  // اعلام تولید توکن جدید
        emit Transfer(address(0), to, amount);          // اعلام انتقال توکن‌های جدید
    }

    // token transaction function 
    function transfer(address to, uint256 amount) external validRecipient(to) returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");  // بررسی موجودی
        balanceOf[msg.sender] -= amount;                                     // کاهش موجودی از فرستنده
        balanceOf[to] += amount;                                              // افزایش موجودی به گیرنده
        emit Transfer(msg.sender, to, amount);                               // اعلام انتقال
        return true;
    }

    // transaction approval 
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;                             // تنظیم مجوز انتقال
        emit Approval(msg.sender, spender, amount);                          // اعلام تایید
        return true;
    }

    // others transaction approval 
    function transferFrom(address from, address to, uint256 amount) external validRecipient(to) returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");  // بررسی موجودی فرستنده
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded"); // بررسی مجوز
        balanceOf[from] -= amount;                                     // کاهش موجودی از فرستنده
        balanceOf[to] += amount;                                       // افزایش موجودی به گیرنده
        allowance[from][msg.sender] -= amount;                         // کاهش مجوز
        emit Transfer(from, to, amount);                                // اعلام انتقال
        return true;
    }

    // Reserve change approval 
    function updateReserveAddress(address newReserve) external onlyOwner validRecipient(newReserve) {
        reserveAddress = newReserve;  // آدرس ذخایر جدید تنظیم می‌شود
    }
}
