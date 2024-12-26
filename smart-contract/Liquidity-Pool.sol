contract OrumyxTokenWithLiquidity {
    address public owner;
    address public orumyxTokenAddress;
    OrumyxToken public orumyxToken;
    IUniswapV2Router02 public uniswapRouter;
    address public liquidityPair;
    
    event LiquidityAdded(uint256 amountOrumyx, uint256 amountToken, uint256 liquidity);
    event LiquidityRemoved(uint256 amountOrumyx, uint256 amountToken);
    
    constructor(address _orumyxTokenAddress, address _uniswapRouter, address _liquidityPair) {
        orumyxTokenAddress = _orumyxTokenAddress;
        orumyxToken = OrumyxToken(_orumyxTokenAddress);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        liquidityPair = _liquidityPair;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute");
        _;
    }

    // Function to add liquidity to Uniswap
    function addLiquidity(uint256 amountOrumyx, uint256 amountToken) external onlyOwner {
        require(orumyxToken.balanceOf(msg.sender) >= amountOrumyx, "Insufficient ORX tokens");

        // Approve the router to spend the tokens
        orumyxToken.approve(address(uniswapRouter), amountOrumyx);

        // Call Uniswap's addLiquidity function
        (uint256 amountAddedOrumyx, uint256 amountAddedToken, uint256 liquidity) = uniswapRouter.addLiquidity(
            address(orumyxToken),
            address(this), // Token B could be another token like USDC or ETH, depending on your LP
            amountOrumyx,
            amountToken,
            0,
            0,
            address(this),
            block.timestamp
        );

        emit LiquidityAdded(amountAddedOrumyx, amountAddedToken, liquidity);
    }

    // Function to remove liquidity from Uniswap
    function removeLiquidity(uint256 liquidity) external onlyOwner {
        // Approve the router to spend liquidity tokens
        IUniswapV2Pair(pair).approve(address(uniswapRouter), liquidity);

        // Call Uniswap's removeLiquidity function
        (uint256 amountOrumyx, uint256 amountToken) = uniswapRouter.removeLiquidity(
            address(orumyxToken),
            address(this),
            liquidity,
            0,
            0,
            address(this),
            block.timestamp
        );

        emit LiquidityRemoved(amountOrumyx, amountToken);
    }

    // Function to swap tokens for liquidity
    function swapTokensForLiquidity(uint256 amountIn, uint256 amountOutMin, address[] calldata path) external onlyOwner {
        orumyxToken.approve(address(uniswapRouter), amountIn);
        uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }
}
