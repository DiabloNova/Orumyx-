// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProposalTimeLock {
    // Governance and Treasury Addresses
    address public governance;
    address public treasury;

    // ERC20 Token Interface for ORX Token
    IERC20 public orumyxToken;

    // Proposal Fee
    uint256 public proposalFee; // Fee required to create a proposal

    // Time-Lock Variables
    uint256 public executionDelay; // Delay time before execution (in seconds)
    mapping(uint256 => uint256) public proposalTimelocks; // Proposal ID => Unlock Time

    // Events
    event ProposalCreated(address indexed proposer, uint256 proposalId, string description);
    event ProposalExecuted(uint256 proposalId);
    event ExecutionDelayUpdated(uint256 newDelay);
    event FeeCollected(address indexed proposer, uint256 amount);

    // Proposal Struct
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 timestamp;
        bool executed;
    }

    // Proposals Mapping and Counter
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Modifiers
    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can execute this");
        _;
    }

    modifier validProposalFee() {
        require(proposalFee > 0, "Proposal fee must be greater than zero");
        _;
    }

    modifier isProposalExecutable(uint256 proposalId) {
        require(block.timestamp >= proposalTimelocks[proposalId], "Proposal is still in time-lock");
        _;
    }

    // Constructor
    constructor(
        address _governance,
        address _treasury,
        address _orumyxToken,
        uint256 _initialFee,
        uint256 _executionDelay
    ) {
        require(_governance != address(0), "Invalid governance address");
        require(_treasury != address(0), "Invalid treasury address");
        require(_orumyxToken != address(0), "Invalid token address");
        require(_initialFee > 0, "Initial fee must be greater than zero");
        require(_executionDelay > 0, "Execution delay must be greater than zero");

        governance = _governance;
        treasury = _treasury;
        orumyxToken = IERC20(_orumyxToken);
        proposalFee = _initialFee;
        executionDelay = _executionDelay;
    }

    // Function to create a proposal with fee payment and timelock initialization
    function createProposal(string memory description) external validProposalFee {
        require(bytes(description).length > 0, "Proposal description cannot be empty");

        // Transfer proposal fee to treasury
        orumyxToken.transferFrom(msg.sender, treasury, proposalFee);
        emit FeeCollected(msg.sender, proposalFee);

        // Create new proposal
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: description,
            proposer: msg.sender,
            timestamp: block.timestamp,
            executed: false
        });

        // Initialize time-lock for execution
        proposalTimelocks[proposalCount] = block.timestamp + executionDelay;

        emit ProposalCreated(msg.sender, proposalCount, description);
    }

    // Function to execute proposals after time-lock expires
    function executeProposal(uint256 proposalId) external onlyGovernance isProposalExecutable(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        // Mark proposal as executed
        proposal.executed = true;

        // Execute proposal logic here (can be expanded for dynamic execution)

        emit ProposalExecuted(proposalId);
    }

    // Function to update execution delay - only callable by governance
    function updateExecutionDelay(uint256 newDelay) external onlyGovernance {
        require(newDelay > 0, "New delay must be greater than zero");
        executionDelay = newDelay;
        emit ExecutionDelayUpdated(newDelay);
    }

    // Function to update proposal fee - only callable by governance
    function updateProposalFee(uint256 newFee) external onlyGovernance {
        require(newFee > 0, "New fee must be greater than zero");
        proposalFee = newFee;
    }

    // Function to update governance address
    function updateGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "Invalid address");
        governance = newGovernance;
    }

    // Function to update treasury address
    function updateTreasury(address newTreasury) external onlyGovernance {
        require(newTreasury != address(0), "Invalid address");
        treasury = newTreasury;
    }

    // View function to get proposal details
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            string memory description,
            address proposer,
            uint256 timestamp,
            bool executed,
            uint256 unlockTime
        )
    {
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.proposer,
            proposal.timestamp,
            proposal.executed,
            proposalTimelocks[proposalId]
        );
    }
}
