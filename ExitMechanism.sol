// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExitAndTermination {
    address public owner;
    bool public contractActive;

    event ContractTerminated(address indexed owner, uint256 timestamp);
    event EmergencyWithdrawal(address indexed user, uint256 amount, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier contractIsActive() {
        require(contractActive, "The contract is no longer active");
        _;
    }

    constructor() {
        owner = msg.sender;
        contractActive = true;
    }

    // Function to stop contract activity
    function terminateContract() public onlyOwner {
        contractActive = false;
        emit ContractTerminated(owner, block.timestamp);
    }

    // Emergency withdrawal for users in case of contract termination or emergency
    function emergencyWithdraw(uint256 amount) public contractIsActive {
        require(amount <= address(msg.sender).balance, "Insufficient balance for withdrawal");
        payable(msg.sender).transfer(amount);
        emit EmergencyWithdrawal(msg.sender, amount, block.timestamp);
    }

    // Function to check if the contract is active
    function isContractActive() public view returns (bool) {
        return contractActive;
    }

    // Fallback function to accept ether transfers
    receive() external payable {}
}
