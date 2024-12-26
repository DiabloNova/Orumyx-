// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ERC20 Token
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

// Interface for DEX integration (like Uniswap or SushiSwap)
interface IDexRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// Main Contract
contract OrumyxGovernance {
    // Variables
    IERC20 public orumyxToken;
    IDexRouter public dexRouter; // DEX Router Address
    address public admin; // Admin Role
    address public pendingAdmin; // For Governance Upgrades

    // Proposal Structure
    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 endTime;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Staking and Reward Pool
    struct RewardPool {
        uint256 totalStaked;
        mapping(address => uint256) stakes;
        mapping(address => uint256) rewards;
        uint256 rewardRate;
    }
    RewardPool public rewardPool;

    // DEX Integration and Liquidity
    address public liquidityPairToken; // Pair token for liquidity
    uint256 public liquidityFee = 1; // Default liquidity fee (1%)

    // Events
    event ProposalCreated(uint256 proposalId, string description, uint256 endTime);
    event ProposalExecuted(uint256 proposalId);
    event LiquidityAdded(uint256 tokenA, uint256 tokenB, uint256 liquidity);
    event Swapped(address indexed user, uint256 amountIn, uint256 amountOut);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    // Constructor
    constructor(address _orumyxToken, address _dexRouter, address _liquidityPairToken) {
        admin = msg.sender;
        orumyxToken = IERC20(_orumyxToken);
        dexRouter = IDexRouter(_dexRouter);
        liquidityPairToken = _liquidityPairToken;
    }

    // DAO Governance Setup
    function proposeNewAdmin(address newAdmin) external onlyAdmin {
        pendingAdmin = newAdmin;
    }

    function acceptAdminRole() external {
        require(msg.sender == pendingAdmin, "Not authorized");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    // Proposal Creation
    function createProposal(string memory description, uint256 duration) external onlyAdmin {
        uint256 endTime = block.timestamp + duration;
        proposals[proposalCount] = Proposal(description, 0, 0, false, endTime);
        emit ProposalCreated(proposalCount, description, endTime);
        proposalCount++;
    }

    // Execute Proposal
    function executeProposal(uint256 proposalId) external onlyAdmin {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }

    // Liquidity Pool Integration
    function addLiquidity(uint256 tokenAmount, uint256 pairAmount) external onlyAdmin {
        orumyxToken.transferFrom(msg.sender, address(this), tokenAmount);
        IERC20(liquidityPairToken).transferFrom(msg.sender, address(this), pairAmount);

        orumyxToken.approve(address(dexRouter), tokenAmount);
        IERC20(liquidityPairToken).approve(address(dexRouter), pairAmount);

        (uint amountA, uint amountB, uint liquidity) = dexRouter.addLiquidity(
            address(orumyxToken),
            liquidityPairToken,
            tokenAmount,
            pairAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        emit LiquidityAdded(amountA, amountB, liquidity);
    }

    function swapTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path) external {
        orumyxToken.transferFrom(msg.sender, address(this), amountIn);
        orumyxToken.approve(address(dexRouter), amountIn);

        dexRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );

        emit Swapped(msg.sender, amountIn, amountOutMin);
    }

    // Reward Pool Management
    function stakeTokens(uint256 amount) external {
        orumyxToken.transferFrom(msg.sender, address(this), amount);
        rewardPool.totalStaked += amount;
        rewardPool.stakes[msg.sender] += amount;
    }

    function claimRewards() external {
        uint256 reward = (rewardPool.stakes[msg.sender] * rewardPool.rewardRate) / 100;
        rewardPool.rewards[msg.sender] = 0;
        orumyxToken.transfer(msg.sender, reward);
    }

    // Dynamic Fee Adjustment
    function updateLiquidityFee(uint256 newFee) external onlyAdmin {
        require(newFee <= 5, "Max fee is 5%");
        liquidityFee = newFee;
    }

    // Audit and Testing Tools
    function auditProposal(uint256 proposalId) external view returns (string memory, uint256, uint256, bool, uint256) {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.executed, proposal.endTime);
    }

    function getStakingDetails(address user) external view returns (uint256, uint256) {
        return (rewardPool.stakes[user], rewardPool.rewards[user]);
    }

    function testLiquidity(uint256 amountA, uint256 amountB) external onlyAdmin returns (bool) {
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        return true;
    }
}
