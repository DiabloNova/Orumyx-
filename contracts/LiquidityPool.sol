// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Liquidity Pool for Orumyx Token
 * @author Orumyx
 * @notice Implements automated market maker (AMM) functionality and dynamic fee structures.
 */

contract LiquidityPool {
    // Token Information
    string public constant name = "Orumyx Liquidity Pool";

    // Pool Variables
    uint256 public totalORX;         // Total ORX in the pool
    uint256 public totalStablecoin;  // Total stablecoin in the pool
    uint256 public constant FEE = 30; // 0.3% Trading fee (in basis points)
    address public admin;

    // AMM Constants (x * y = k)
    uint256 public constantProduct;

    // Events
    event LiquidityAdded(address indexed provider, uint256 orxAmount, uint256 stableAmount);
    event LiquidityRemoved(address indexed provider, uint256 orxAmount, uint256 stableAmount);
    event Swapped(address indexed trader, uint256 inputAmount, uint256 outputAmount, bool isBuy);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Add Liquidity
    function addLiquidity(uint256 orxAmount, uint256 stableAmount) external onlyAdmin {
        require(orxAmount > 0 && stableAmount > 0, "Invalid amounts");

        // Update pool balances
        totalORX += orxAmount;
        totalStablecoin += stableAmount;

        // Calculate constant product
        if (constantProduct == 0) {
            constantProduct = totalORX * totalStablecoin;
        } else {
            require(totalORX * totalStablecoin >= constantProduct, "Liquidity pool error");
        }

        emit LiquidityAdded(msg.sender, orxAmount, stableAmount);
    }

    // Remove Liquidity
    function removeLiquidity(uint256 sharePercent) external onlyAdmin {
        require(sharePercent > 0 && sharePercent <= 100, "Invalid percentage");

        uint256 orxOut = (totalORX * sharePercent) / 100;
        uint256 stableOut = (totalStablecoin * sharePercent) / 100;

        // Update pool balances
        totalORX -= orxOut;
        totalStablecoin -= stableOut;
        constantProduct = totalORX * totalStablecoin;

        emit LiquidityRemoved(msg.sender, orxOut, stableOut);
    }

    // Swap ORX for Stablecoin
    function swapORXForStable(uint256 orxAmount) external returns (uint256) {
        require(orxAmount > 0, "Invalid ORX amount");

        uint256 newORXBalance = totalORX + orxAmount;
        uint256 newStableBalance = constantProduct / newORXBalance;

        uint256 stableOut = totalStablecoin - newStableBalance;

        // Apply fee
        uint256 fee = (stableOut * FEE) / 10000;
        stableOut -= fee;

        // Update balances
        totalORX = newORXBalance;
        totalStablecoin = newStableBalance;

        emit Swapped(msg.sender, orxAmount, stableOut, true);
        return stableOut;
    }

    // Swap Stablecoin for ORX
    function swapStableForORX(uint256 stableAmount) external returns (uint256) {
        require(stableAmount > 0, "Invalid stablecoin amount");

        uint256 newStableBalance = totalStablecoin + stableAmount;
        uint256 newORXBalance = constantProduct / newStableBalance;

        uint256 orxOut = totalORX - newORXBalance;

        // Apply fee
        uint256 fee = (orxOut * FEE) / 10000;
        orxOut -= fee;

        // Update balances
        totalORX = newORXBalance;
        totalStablecoin = newStableBalance;

        emit Swapped(msg.sender, stableAmount, orxOut, false);
        return orxOut;
    }

    // Dynamic Fee Adjustment
    function updateFee(uint256 newFee) external onlyAdmin {
        require(newFee <= 100, "Fee too high"); // Max 1%
        emit Swapped(admin, FEE, newFee, false);
    }

    // Admin Functions
    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        admin = newAdmin;
    }

    // Emergency Pool Lock
    function emergencyLock() external onlyAdmin {
        constantProduct = 0; // Disable trading by breaking AMM formula
    }
}

