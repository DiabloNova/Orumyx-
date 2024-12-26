// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimal ERC20 Interface for ORX Token
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ProposalDelegation {
    // Governance and Token
    address public governance;
    IERC20 public orumyxToken;

    // Proposal Structure
    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
    }

    // Delegation Mapping
    mapping(address => address) public delegate; // Delegator => Delegatee
    mapping(address => uint256) public votingPower; // Tracks voting power

    // Proposal Tracking
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    // Events
    event ProposalCreated(uint256 id, string description, uint256 startTime, uint256 endTime);
    event VoteCast(address indexed voter, uint256 proposalId, bool support, uint256 weight);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event ProposalExecuted(uint256 id);
    event ProposalCanceled(uint256 id);
    event GovernanceUpdated(address newGovernance);

    // Modifiers
    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance can execute this");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].id > 0, "Proposal does not exist");
        _;
    }

    modifier proposalActive(uint256 proposalId) {
        require(block.timestamp >= proposals[proposalId].startTime, "Proposal has not started");
        require(block.timestamp < proposals[proposalId].endTime, "Proposal has ended");
        _;
    }

    // Constructor
    constructor(address _governance, address _orumyxToken) {
        require(_governance != address(0), "Invalid governance address");
        require(_orumyxToken != address(0), "Invalid token address");

        governance = _governance;
        orumyxToken = IERC20(_orumyxToken);
    }

    // Create Proposal
    function createProposal(string memory description, uint256 duration) external onlyGovernance {
        require(duration > 0, "Duration must be greater than zero");

        proposalCount++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            startTime: startTime,
            endTime: endTime,
            executed: false,
            canceled: false
        });

        emit ProposalCreated(proposalCount, description, startTime, endTime);
    }

    // Delegate Voting Power
    function delegateVote(address to) external {
        require(to != msg.sender, "Cannot delegate to self");
        address previousDelegate = delegate[msg.sender];
        delegate[msg.sender] = to;

        _moveVotingPower(previousDelegate, to, orumyxToken.balanceOf(msg.sender));
        emit DelegateChanged(msg.sender, previousDelegate, to);
    }

    // Cast Vote (Direct or Delegated)
    function castVote(uint256 proposalId, bool support) external proposalExists(proposalId) proposalActive(proposalId) {
        uint256 weight = _getVotingPower(msg.sender);
        require(weight > 0, "No voting power available");

        Proposal storage proposal = proposals[proposalId];

        if (support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }

        emit VoteCast(msg.sender, proposalId, support, weight);
    }

    // Execute Proposal
    function executeProposal(uint256 proposalId) external onlyGovernance proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal rejected");

        proposal.executed = true;

        // Execute proposal logic (to be customized for governance actions)
        emit ProposalExecuted(proposalId);
    }

    // Cancel Proposal
    function cancelProposal(uint256 proposalId) external onlyGovernance proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    // Update Governance
    function updateGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "Invalid governance address");
        governance = newGovernance;
        emit GovernanceUpdated(newGovernance);
    }

    // Internal Functions

    // Adjust voting power during delegation changes
    function _moveVotingPower(address from, address to, uint256 amount) internal {
        if (from != address(0)) {
            votingPower[from] -= amount;
        }
        if (to != address(0)) {
            votingPower[to] += amount;
        }
    }

    // Get Voting Power
    function _getVotingPower(address account) internal view returns (uint256) {
        if (delegate[account] != address(0)) {
            return votingPower[delegate[account]];
        }
        return orumyxToken.balanceOf(account);
    }

    // View Functions
    function getProposalDetails(uint256 proposalId) external view returns (
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool canceled
    ) {
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.canceled
        );
    }

    function getDelegate(address account) external view returns (address) {
        return delegate[account];
    }

    function getVotingPower(address account) external view returns (uint256) {
        return _getVotingPower(account);
    }
}
