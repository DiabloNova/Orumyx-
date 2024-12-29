// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenValue {
    string public constant name ="Orumyx";
    string public constant symbol = "ORX";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(uint256 initialSupply) {owner = msg.sender;
        totalSupply = initialSupply * 10**decimals;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);}modifier onlyOwner() {
        require(msg.
