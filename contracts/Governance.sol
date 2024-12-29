// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Governance Contract for Orumyx Token
 * @author Orumyx
 * @notice Implements decentralized governance for proposal creation, voting, and execution.
 */

contract Governance {
    // Governance Variables
    string public constant name = "Orumyx Governance";
    address public admin;

    // Governance Tokenomics
    uint256 public constant MINIMUM_QUORUM_PERCENTAGE = 20; // 20% quorum
    uint256 public constant APPROVAL_THRESHOLD_PERCENTAGE = 51; // 51% approval
    uint256 public constant PROPOSAL_DEPOSIT = 1000 * 10**18; // Minimum deposit of 1000 ORX tokens
    uint256 public constant PROPOSAL_DURATION = 7 days; // Voting period duration

    // Proposal Structure
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public proposalCount;

    // Events
    event ProposalCreated(uint256 id, address proposer, string description, uint256 deadline);
    event VoteCast(uint256 id, address voter, bool support);
    event ProposalExecuted(uint256 id);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this function");
        _;
    }

    modifier validProposal(uint256 proposalId) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        _;
    }

    constructor() {
        admin = msg.sender; // Contract deployer becomes admin
    }

    /**
     * @notice Submit a new proposal.
     * @param description Proposal description.
     */
    function createProposal(string memory description) external payable {
        require(msg.value == PROPOSAL_DEPOSIT, "Deposit required to create proposal");

        uint256 deadline = block.timestamp + PROPOSAL_DURATION;
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

    /**
     * @notice Vote on a proposal.
     * @param proposalId ID of the proposal to vote on.
     * @param support True if voting in favor, false otherwise.
     */
    function vote(uint256 proposalId, bool support) external validProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.deadline, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @notice Execute a proposal if it meets quorum and approval requirements.
     * @param proposalId ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external validProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period not yet ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalVotes * 100) / proposalCount;

        require(quorum >= MINIMUM_QUORUM_PERCENTAGE, "Quorum not reached");

        if ((proposal.votesFor * 100) / totalVotes >= APPROVAL_THRESHOLD_PERCENTAGE) {
            proposal.executed = true;
            emit ProposalExecuted(proposalId);
        }
    }

    /**
     * @notice Update the admin address.
     * @param newAdmin Address of the new admin.
     */
    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        admin = newAdmin;
    }

    /**
     * @notice Emergency function to pause all proposals.
     */
    function emergencyPause() external onlyAdmin {
        for (uint256 i = 0; i < proposalCount; i++) {
            Proposal storage proposal = proposals[i];
            proposal.deadline = block.timestamp; // Force expiration
        }
    }

    /**
     * @notice Withdraw deposits for canceled or expired proposals.
     */
    function withdrawDeposit() external onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }

    // Fallback function to receive deposits
    receive() external payable {}
}

