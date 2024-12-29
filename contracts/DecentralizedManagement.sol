// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract DecentralizedManagement {
    // Governance Configuration
    string public constant name = "Orumyx Decentralized Management";
    address public owner;

    // Governance Roles and Parameters
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
    }

    uint256 public proposalCount;
    uint256 public minQuorumPercentage = 20; // Minimum 20% quorum
    uint256 public approvalThreshold = 51;  // 51% votes needed for approval
    uint256 public proposalDuration = 7 days;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public isVoter;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Events
    event ProposalCreated(uint256 id, address proposer, string description, uint256 deadline);
    event VoteCast(uint256 id, address voter, bool support);
    event ProposalExecuted(uint256 id);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyVoter() {
        require(isVoter[msg.sender], "Not authorized to vote");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Add Voter
    function addVoter(address voter) external onlyOwner {
        require(voter != address(0), "Invalid address");
        isVoter[voter] = true;
    }

    // Remove Voter
    function removeVoter(address voter) external onlyOwner {
        require(isVoter[voter], "Voter does not exist");
        isVoter[voter] = false;
    }

    // Submit Proposal
    function createProposal(string memory description) external onlyVoter {
        uint256 deadline = block.timestamp + proposalDuration;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            deadline: deadline,
            executed: false
        });

        emit ProposalCreated(proposalCount, msg.sender, description, deadline);
        proposalCount++;
    }

    // Vote on Proposal
    function voteOnProposal(uint256 proposalId, bool support) external onlyVoter {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;
        if (support) {
            proposal.votesFor += 1;
        } else {
            proposal.votesAgainst += 1;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    // Execute Proposal
    function executeProposal(uint256 proposalId) external onlyVoter {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalVotes * 100) / proposalCount;

        require(quorum >= minQuorumPercentage, "Quorum not reached");

        if (proposal.votesFor * 100 / totalVotes > approvalThreshold) {
            proposal.executed = true;
            emit ProposalExecuted(proposalId);
        }
    }

    // Adjust Governance Parameters
    function updateQuorumPercentage(uint256 newQuorum) external onlyOwner {
        require(newQuorum > 0 && newQuorum <= 100, "Invalid quorum percentage");
        minQuorumPercentage = newQuorum;
    }

    function updateApprovalThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0 && newThreshold <= 100, "Invalid approval threshold");
        approvalThreshold = newThreshold;
    }

    function updateProposalDuration(uint256 newDuration) external onlyOwner {
        require(newDuration > 0, "Invalid duration");
        proposalDuration = newDuration;
    }

    // Emergency Functions
    function emergencyPauseProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        proposal.deadline = block.timestamp; // Force expiration
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}

