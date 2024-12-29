// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Investment Pool for Orumyx Token
 * @author Orumyx
 * @notice Manages diversified investments, yield optimization, and risk mitigation.
 */

contract InvestmentPool {
    // Pool Variables
    string public constant name = "Orumyx Investment Pool";
    address public admin;

    struct Investment {
        string assetName;
        uint256 amount;
        uint256 weight; // Weight in percentage
        uint256 returnRate; // Annual return rate in percentage
        bool active;
    }

    Investment[] public investments;
    mapping(uint256 => uint256) public yields; // Tracks pool yields by time
    uint256 public totalWeight; // Total weight for portfolio optimization

    // Emergency Fund
    uint256 public emergencyFund; // Reserve fund for emergencies
    uint256 public constant EMERGENCY_PERCENT = 5; // 5% allocation to emergency fund

    // Events
    event InvestmentAdded(uint256 indexed id, string assetName, uint256 amount, uint256 weight, uint256 returnRate);
    event EmergencyFundUpdated(uint256 newFund);
    event YieldReported(uint256 indexed timestamp, uint256 yield);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /**
     * @notice Add a new investment to the pool.
     * @param assetName Name of the asset.
     * @param amount Amount invested.
     * @param weight Weight percentage of the asset in the pool.
     * @param returnRate Expected annual return rate.
     */
    function addInvestment(
        string memory assetName,
        uint256 amount,
        uint256 weight,
        uint256 returnRate
    ) external onlyAdmin {
        require(weight > 0 && weight <= 100, "Invalid weight");
        require(returnRate > 0, "Invalid return rate");

        investments.push(Investment({
            assetName: assetName,
            amount: amount,
            weight: weight,
            returnRate: returnRate,
            active: true
        }));

        totalWeight += weight;

        emit InvestmentAdded(investments.length - 1, assetName, amount, weight, returnRate);
    }

    /**
     * @notice Calculate the expected return of the pool.
     * @return totalReturn Weighted average return of the pool.
     */
    function calculateReturns() public view returns (uint256 totalReturn) {
        uint256 weightedSum = 0;

        for (uint256 i = 0; i < investments.length; i++) {
            if (investments[i].active) {
                weightedSum += (investments[i].returnRate * investments[i].weight);
            }
        }

        totalReturn = weightedSum / totalWeight;
    }

    /**
     * @notice Report yield earned during a given period.
     * @param timestamp Timestamp of the report.
     */
    function reportYield(uint256 timestamp) external onlyAdmin {
        uint256 yield = calculateReturns();
        yields[timestamp] = yield;

        emit YieldReported(timestamp, yield);
    }

    /**
     * @notice Allocate emergency funds from treasury growth.
     * @param growthAmount Total growth in treasury.
     */
    function allocateEmergencyFund(uint256 growthAmount) external onlyAdmin {
        uint256 allocation = (growthAmount * EMERGENCY_PERCENT) / 100;
        emergencyFund += allocation;

        emit EmergencyFundUpdated(emergencyFund);
    }

    /**
     * @notice Update admin address.
     * @param newAdmin Address of the new admin.
     */
    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        admin = newAdmin;
    }

    /**
     * @notice Emergency withdrawal to protect funds.
     * @param amount Amount to withdraw.
     * @param recipient Address to receive the funds.
     */
    function emergencyWithdraw(uint256 amount, address recipient) external onlyAdmin {
        require(amount <= emergencyFund, "Insufficient emergency fund");
        require(recipient != address(0), "Invalid recipient address");

        emergencyFund -= amount;
        payable(recipient).transfer(amount);
    }

    /**
     * @notice Fetch total number of investments.
     * @return count Total number of investments.
     */
    function getInvestmentCount() public view returns (uint256 count) {
        return investments.length;
    }

    /**
     * @notice Deactivate an investment.
     * @param id Investment ID to deactivate.
     */
    function deactivateInvestment(uint256 id) external onlyAdmin {
        require(id < investments.length, "Invalid investment ID");
        investments[id].active = false;
    }

    // Fallback to receive Ether for emergency fund
    receive() external payable {}
}

