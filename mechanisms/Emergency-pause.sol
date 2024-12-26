// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EmergencyPause {
    // Address with permission to toggle pause state
    address public governance;

    // Boolean variable to track paused state
    bool public paused = false;

    // Event to log when the contract is paused or unpaused
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    // Modifier to restrict function access when paused
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can execute this");
        _;
    }

    // Constructor to set initial governance address
    constructor(address _governance) {
        require(_governance != address(0), "Governance address cannot be zero");
        governance = _governance;
    }

    // Function to pause the contract - only callable by governance
    function pauseContract() external onlyGovernance whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    // Function to unpause the contract - only callable by governance
    function unpauseContract() external onlyGovernance whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // Emergency function to transfer governance in case the current one is compromised
    function transferGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "New governance cannot be zero address");
        governance = newGovernance;
    }

    // Example of a protected function using 'whenNotPaused'
    function criticalFunction() external whenNotPaused {
        // Logic for critical operation
    }

    // Example of a function allowed during paused state
    function emergencyWithdraw() external whenPaused {
        // Logic to allow users to withdraw during emergency situations
    }
}
