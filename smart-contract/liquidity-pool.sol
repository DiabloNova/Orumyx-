// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxLiquidityPool {

    address public orumyxTokenAddress;
    OrumyxToken public orumyxToken;

    // Liquidity pool token struct
    struct LiquidityProvider {
        uint256 amountOrumyx;
        uint256 amountCollateral;
        uint256 liquidityTokens;
    }

    // Mapping to store liquidity providers' information
    mapping(address => LiquidityProvider) public liquidityProviders;

    // Total liquidity tokens
    uint256 public totalLiquidityTokens;

    // Reserve amounts
    uint256 public collateralReserve;
    uint256 public liquidityReserve;

    // Events
    event LiquidityProvided(address indexed provider, uint256 amountOrumyx, uint256 amountCollateral, uint256 liquidityTokensMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountOrumyx, uint256 amountCollateral, uint256 liquidityTokensBurned);
    event LiquidityPoolBalanceUpdated(uint256 newCollateralReserve, uint256 newLiquidityReserve);

    constructor(address _orumyxTokenAddress) {
        orumyxTokenAddress = _orumyxTokenAddress;
        orumyxToken = OrumyxToken(_orumyxTokenAddress);
    }

    // Function to provide liquidity to the pool
    function provideLiquidity(uint256 _amountOrumyx, uint256 _amountCollateral) external returns (uint256 liquidityTokensMinted) {
        require(_amountOrumyx > 0 && _amountCollateral > 0, "Amount must be greater than zero");

        // Transfer the ORX tokens and collateral to the contract
        orumyxToken.transferFrom(msg.sender, address(this), _amountOrumyx);

        // Assuming collateral is another ERC20 token, you would add the token contract for collateral
        // ERC20(collateralTokenAddress).transferFrom(msg.sender, address(this), _amountCollateral);

        // Calculate liquidity tokens minted, proportionate to the reserve
        liquidityTokensMinted = (_amountOrumyx + _amountCollateral) * totalLiquidityTokens / (liquidityReserve + collateralReserve);

        // Update liquidity pool and user data
        liquidityProviders[msg.sender].amountOrumyx += _amountOrumyx;
        liquidityProviders[msg.sender].amountCollateral += _amountCollateral;
        liquidityProviders[msg.sender].liquidityTokens += liquidityTokensMinted;

        totalLiquidityTokens += liquidityTokensMinted;
        liquidityReserve += _amountOrumyx;
        collateralReserve += _amountCollateral;

        emit LiquidityProvided(msg.sender, _amountOrumyx, _amountCollateral, liquidityTokensMinted);
        emit LiquidityPoolBalanceUpdated(collateralReserve, liquidityReserve);

        return liquidityTokensMinted;
    }

    // Function to remove liquidity from the pool
    function removeLiquidity(uint256 _liquidityTokensToBurn) external returns (uint256 amountOrumyx, uint256 amountCollateral) {
        require(_liquidityTokensToBurn > 0, "Amount must be greater than zero");
        require(liquidityProviders[msg.sender].liquidityTokens >= _liquidityTokensToBurn, "Insufficient liquidity tokens");

        // Calculate the proportionate amount of ORX and collateral to be withdrawn
        uint256 providerShareOrumyx = liquidityReserve * _liquidityTokensToBurn / totalLiquidityTokens;
        uint256 providerShareCollateral = collateralReserve * _liquidityTokensToBurn / totalLiquidityTokens;

        // Update liquidity pool and user data
        liquidityProviders[msg.sender].amountOrumyx -= providerShareOrumyx;
        liquidityProviders[msg.sender].amountCollateral -= providerShareCollateral;
        liquidityProviders[msg.sender].liquidityTokens -= _liquidityTokensToBurn;

        totalLiquidityTokens -= _liquidityTokensToBurn;
        liquidityReserve -= providerShareOrumyx;
        collateralReserve -= providerShareCollateral;

        // Transfer the amounts back to the liquidity provider
        orumyxToken.transfer(msg.sender, providerShareOrumyx);
        // ERC20(collateralTokenAddress).transfer(msg.sender, providerShareCollateral);

        emit LiquidityRemoved(msg.sender, providerShareOrumyx, providerShareCollateral, _liquidityTokensToBurn);
        emit LiquidityPoolBalanceUpdated(collateralReserve, liquidityReserve);

        return (providerShareOrumyx, providerShareCollateral);
    }

    // Function to get the current liquidity pool balance
    function getLiquidityPoolBalance() external view returns (uint256, uint256) {
        return (liquidityReserve, collateralReserve);
    }
    
    // Function to get the liquidity of a specific provider
    function getProviderLiquidity(address provider) external view returns (uint256, uint256, uint256) {
        return (
            liquidityProviders[provider].amountOrumyx,
            liquidityProviders[provider].amountCollateral,
            liquidityProviders[provider].liquidityTokens
        );
    }
}

contract OrumyxStabilization {
    address public orumyxTokenAddress;
    OrumyxToken public orumyxToken;

    // Stabilization reserves (could include assets like stablecoins, real-world commodities, etc.)
    uint256 public stabilizationReserve;
    uint256 public targetPrice;
    uint256 public currentPrice;

    // Event for stabilization reserve updates
    event StabilizationReserveUpdated(uint256 newReserveAmount);
    event PriceAdjusted(uint256 newPrice);

    constructor(address _orumyxTokenAddress, uint256 _targetPrice) {
        orumyxTokenAddress = _orumyxTokenAddress;
        orumyxToken = OrumyxToken(_orumyxTokenAddress);
        targetPrice = _targetPrice;
    }

    // Function to adjust the price of ORX using stabilization reserves
    function adjustPrice(uint256 _newPrice) external {
        require(_newPrice > 0, "Price must be greater than zero");

        currentPrice = _newPrice;
        if (currentPrice < targetPrice) {
            // Use stabilization reserve to buy back ORX tokens from the market
            uint256 tokensToBuyBack = (targetPrice - currentPrice) * stabilizationReserve / targetPrice;
            require(orumyxToken.balanceOf(address(this)) >= tokensToBuyBack, "Insufficient reserve to stabilize price");

            orumyxToken.transfer(msg.sender, tokensToBuyBack);  // Transfer ORX to the market to stabilize

            emit PriceAdjusted(_newPrice);
        } else if (currentPrice > targetPrice) {
            // Use stabilization reserve to sell ORX tokens
            uint256 tokensToSell = (currentPrice - targetPrice) * stabilizationReserve / targetPrice;
            require(orumyxToken.balanceOf(msg.sender) >= tokensToSell, "Insufficient ORX to sell");

            // Transfer ORX tokens to the stabilization contract
            orumyxToken.transferFrom(msg.sender, address(this), tokensToSell);

            emit PriceAdjusted(_newPrice);
        }

        emit StabilizationReserveUpdated(stabilizationReserve);
    }

    // Function to update stabilization reserves manually (could be part of DAO governance)
    function updateStabilizationReserve(uint256 _newReserve) external {
        stabilizationReserve = _newReserve;
        emit StabilizationReserveUpdated(_newReserve);
    }

    // Function to get current reserve status
    function getReserveStatus() external view returns (uint256, uint256, uint256) {
        return (stabilizationReserve, targetPrice, currentPrice);
    }
}
