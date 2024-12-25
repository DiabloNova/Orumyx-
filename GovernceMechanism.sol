// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxGovernance {

    address public owner;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public userVotes;

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 voteCount;
        bool executed;
        mapping(address => bool) votes;
    }

    event ProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCasted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, string result);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier notExecuted(uint256 proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }

    modifier hasNotVoted(uint256 proposalId) {
        require(!proposals[proposalId].votes[msg.sender], "You already voted for this proposal");
        _;
    }

    constructor() {
        owner = msg.sender;
        proposalCount = 0;
    }

    // تابع برای ایجاد یک پیشنهاد جدید
    function createProposal(string memory description) external onlyOwner {
        uint256 proposalId = proposalCount++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.description = description;
        newProposal.proposer = msg.sender;
        newProposal.voteCount = 0;
        newProposal.executed = false;

        emit ProposalCreated(proposalId, description, msg.sender);
    }

    // تابع برای رأی دادن به پیشنهاد
    function vote(uint256 proposalId, bool voteOption) external hasNotVoted(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Invalid proposal ID");

        if (voteOption) {
            proposal.voteCount++;
        } else {
            proposal.voteCount--;
        }

        proposal.votes[msg.sender] = true;
        emit VoteCasted(proposalId, msg.sender, voteOption);
    }

    // تابع برای اجرای پیشنهاد پس از رأی‌گیری
    function executeProposal(uint256 proposalId) external onlyOwner notExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.voteCount > 0, "Proposal has no majority vote");

        // انجام عملیات مرتبط با اجرای پیشنهاد
        proposal.executed = true;
        emit ProposalExecuted(proposalId, "Proposal executed successfully");
    }

    // تابع برای مشاهده وضعیت یک پیشنهاد
    function getProposalStatus(uint256 proposalId) external view returns (string memory description, uint256 voteCount, bool executed) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.description, proposal.voteCount, proposal.executed);
    }
}
