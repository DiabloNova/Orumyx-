// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOrumyxToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DAOGovernance {
    IOrumyxToken public orumyxToken;
    uint256 public proposalIdCounter;
    uint256 public quorumPercentage = 20;  // 20% quorum for proposal
    uint256 public passThreshold = 51;    // 51% approval to pass the proposal
    uint256 public feePercentage = 2;     // Fee percentage on transfers to fund the DAO (2%)
    address public daoTreasury;           // DAO treasury address

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
        bool expired;  // Proposal expiry status
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes;
    mapping(address => uint256) public lastVoteUpdate;  // Track the last vote power change

    event ProposalCreated(uint256 proposalId, address proposer, string description, uint256 voteStart, uint256 voteEnd);
    event VoteCast(address voter, uint256 proposalId, bool support);
    event ProposalExecuted(uint256 proposalId, bool passed);
    event ProposalExpired(uint256 proposalId);
    event FeeTransferredToDAO(address from, uint256 amount);

    constructor(address _orumyxToken, address _daoTreasury) {
        orumyxToken = IOrumyxToken(_orumyxToken);
        daoTreasury = _daoTreasury;
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

    // Fee mechanism to transfer a percentage of tokens to the DAO's treasury on each transaction
    function _transferWithFee(address sender, address recipient, uint256 amount) internal {
        uint256 feeAmount = (amount * feePercentage) / 100;
        uint256 amountAfterFee = amount - feeAmount;

        // Transfer the fee to the DAO's treasury
        orumyxToken.transferFrom(sender, daoTreasury, feeAmount);
        emit FeeTransferredToDAO(sender, feeAmount);

        // Transfer the remaining amount to the recipient
        orumyxToken.transferFrom(sender, recipient, amountAfterFee);
    }

    // Dynamic voting power based on token balance
    function getVotingPower(address account) public view returns (uint256) {
        return orumyxToken.balanceOf(account);
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

        uint256 voterWeight = getVotingPower(msg.sender);  // Get current voting power
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
