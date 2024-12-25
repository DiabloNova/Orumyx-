// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptoToken {
    string public name = "CryptoToken";
    string public symbol = "CTK";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    address public owner;
    address public reserveAddress;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensMinted(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0), "Invalid recipient address");
        _;
    }

    constructor(address _reserveAddress) {
        owner = msg.sender;
        reserveAddress = _reserveAddress;
        totalSupply = 1000000 * (10 ** uint256(decimals));  // Initial supply of 1 million tokens
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);  // Emit transfer event for minting
    }

    function mint(address to, uint256 amount) external onlyOwner validRecipient(to) {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit TokensMinted(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external validRecipient(to) returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external validRecipient(to) returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function updateReserveAddress(address newReserve) external onlyOwner validRecipient(newReserve) {
        reserveAddress = newReserve;
    }
}
