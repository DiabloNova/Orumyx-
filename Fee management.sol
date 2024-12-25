// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeeManagement {
    address public owner;
    uint256 public transactionFee;  // fee in wei
    uint256 public withdrawalFee;  // fee in wei
    address public feeRecipient;

    event TransactionFeeUpdated(uint256 oldFee, uint256 newFee, uint256 timestamp);
    event WithdrawalFeeUpdated(uint256 oldFee, uint256 newFee, uint256 timestamp);
    event FeesWithdrawn(address indexed recipient, uint256 amount, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can update fees");
        _;
    }

    constructor(address _feeRecipient, uint256 _transactionFee, uint256 _withdrawalFee) {
        owner = msg.sender;
        feeRecipient = _feeRecipient;
        transactionFee = _transactionFee;
        withdrawalFee = _withdrawalFee;
    }

    // Function to update transaction fee
    function updateTransactionFee(uint256 newFee) public onlyOwner {
        uint256 oldFee = transactionFee;
        transactionFee = newFee;
        emit TransactionFeeUpdated(oldFee, newFee, block.timestamp);
    }

    // Function to update withdrawal fee
    function updateWithdrawalFee(uint256 newFee) public onlyOwner {
        uint256 oldFee = withdrawalFee;
        withdrawalFee = newFee;
        emit WithdrawalFeeUpdated(oldFee, newFee, block.timestamp);
    }

    // Function to withdraw fees accumulated in the contract
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = feeRecipient.call{value: balance}("");
        require(success, "Failed to withdraw fees");
        emit FeesWithdrawn(feeRecipient, balance, block.timestamp);
    }

    // Function to calculate the transaction fee for a given amount
    function calculateTransactionFee(uint256 amount) public view returns (uint256) {
        return (amount * transactionFee) / 10000;  // Fee as a percentage
    }

    // Function to calculate the withdrawal fee for a given amount
    function calculateWithdrawalFee(uint256 amount) public view returns (uint256) {
        return (amount * withdrawalFee) / 10000;  // Fee as a percentage
    }

    // Fallback function to accept Ether
    receive() external payable {}
}
