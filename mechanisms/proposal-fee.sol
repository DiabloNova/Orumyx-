// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProposalFeeMechanism {
    // Governance and Treasury Addresses
    address public governance;
    address public treasury;

    // ERC20 Token Interface for ORX Token
    IERC20 public orumyxToken;

    // Proposal Fee
    uint256 public proposalFee; // Fee required to create a proposal

    // Events
    event ProposalCreated(address indexed proposer, uint256 proposalId, string description);
    event ProposalFeeUpdated(uint256 newFee);
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

    // Constructor
    constructor(
        address _governance,
        address _treasury,
        address _orumyxToken,
        uint256 _initialFee
    ) {
        require(_governance != address(0), "Invalid governance address");
        require(_treasury != address(0), "Invalid treasury address");
        require(_orumyxToken != address(0), "Invalid token address");
        require(_initialFee > 0, "Initial fee must be greater than zero");

        governance = _governance;
        treasury = _treasury;
        orumyxToken = IERC20(_orumyxToken);
        proposalFee = _initialFee;
    }

    // Function to create a proposal with fee payment
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

        emit ProposalCreated(msg.sender, proposalCount, description);
    }

    // Function to update the proposal fee - only callable by governance
    function updateProposalFee(uint256 newFee) external onlyGovernance {
        require(newFee > 0, "New fee must be greater than zero");
        proposalFee = newFee;
        emit ProposalFeeUpdated(newFee);
    }

    // Function to execute proposals (Placeholder for real execution logic)
    function executeProposal(uint256 proposalId) external onlyGovernance {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        proposal.executed = true;

        // Execute proposal logic here (e.g., funding, governance actions)
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
            bool executed
        )
    {
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.proposer,
            proposal.timestamp,
            proposal.executed
        );
    }
}
