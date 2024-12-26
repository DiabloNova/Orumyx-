// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOrumyxToken {
    function balanceOf(address account) external view returns (uint256);
}

contract DAOGovernance {
    IOrumyxToken public orumyxToken;
    uint256 public proposalIdCounter;
    uint256 public quorumPercentage = 20;  // 20% quorum for proposal
    uint256 public passThreshold = 51;    // 51% approval to pass the proposal

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 totalVotes;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        bool expired;  // New field to track expiry status
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes;

    event ProposalCreated(uint256 proposalId, address proposer, string description, uint256 voteStart, uint256 voteEnd);
    event VoteCast(address voter, uint256 proposalId, bool support);
    event ProposalExecuted(uint256 proposalId, bool passed);
    event ProposalExpired(uint256 proposalId);

    constructor(address _orumyxToken) {
        orumyxToken = IOrumyxToken(_orumyxToken);
    }

    modifier onlyTokenHolders() {
        require(orumyxToken.balanceOf(msg.sender) > 0, "Must hold tokens to vote");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].id != 0, "Proposal does not exist");
        _;
    }

    modifier activeProposal(uint256 proposalId) {
        require(block.timestamp >= proposals[proposalId].voteStart, "Voting has not started");
        require(block.timestamp <= proposals[proposalId].voteEnd, "Voting period has ended");
        _;
    }

    modifier proposalNotExpired(uint256 proposalId) {
        require(!proposals[proposalId].expired, "Proposal has expired");
        _;
    }

    function createProposal(string memory description, uint256 duration) external onlyTokenHolders {
        proposalIdCounter++;
        uint256 proposalId = proposalIdCounter;

        uint256 voteStart = block.timestamp;
        uint256 voteEnd = voteStart + duration;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            voteStart: voteStart,
            voteEnd: voteEnd,
            totalVotes: 0,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false,
            expired: false
        });

        emit ProposalCreated(proposalId, msg.sender, description, voteStart, voteEnd);
    }

    function vote(uint256 proposalId, bool support) external onlyTokenHolders activeProposal(proposalId) proposalNotExpired(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!votes[msg.sender][proposalId], "You already voted on this proposal");

        uint256 voterWeight = orumyxToken.balanceOf(msg.sender);
        votes[msg.sender][proposalId] = true;

        proposal.totalVotes += voterWeight;

        if (support) {
            proposal.votesFor += voterWeight;
        } else {
            proposal.votesAgainst += voterWeight;
        }

        emit VoteCast(msg.sender, proposalId, support);
    }

    function closeVoting(uint256 proposalId) internal proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        // If voting period has ended, and quorum is not reached, mark proposal as expired
        if (block.timestamp > proposal.voteEnd && proposal.totalVotes < (proposal.totalVotes * quorumPercentage) / 100) {
            proposal.expired = true;
            emit ProposalExpired(proposalId);
        }
    }

    function executeProposal(uint256 proposalId) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.voteEnd, "Voting period not over");
        require(!proposal.executed, "Proposal already executed");

        closeVoting(proposalId);

        if (proposal.expired) {
            return; // Do nothing if the proposal is expired
        }

        uint256 quorum = (proposal.totalVotes * quorumPercentage) / 100;
        require(proposal.totalVotes >= quorum, "Quorum not reached");

        proposal.passed = (proposal.votesFor * 100) / proposal.totalVotes >= passThreshold;

        if (proposal.passed) {
            // Execute the proposal action here, e.g., fund allocation, contract changes
            // For example: executeProposalAction(proposalId);
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.passed);
    }

    // Allow the contract to receive ether for use in proposals
    receive() external payable {}
}
