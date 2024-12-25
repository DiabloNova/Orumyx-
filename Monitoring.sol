// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ModificationsAndUpdates {
    address public owner;
    mapping(address => uint256) public userBalances;
    uint256 public lastUpdated;

    event OwnerUpdated(address indexed previousOwner, address indexed newOwner);
    event ContractUpdated(string updateDescription, uint256 timestamp);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        lastUpdated = block.timestamp;
    }

    // Function to update the owner of the contract
    function updateOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address cannot be the zero address");
        emit OwnerUpdated(owner, newOwner);
        owner = newOwner;
    }

    // Function to perform an update to the contract (e.g., upgrading functionality)
    function performContractUpdate(string memory updateDescription) public onlyOwner {
        lastUpdated = block.timestamp;
        emit ContractUpdated(updateDescription, lastUpdated);
    }

    // Function to check contract last update time
    function getLastUpdateTime() public view returns (uint256) {
        return lastUpdated;
    }

    // Function to update user balances (demonstrative purpose)
    function updateUserBalance(address user, uint256 newBalance) public onlyOwner {
        userBalances[user] = newBalance;
    }
}
