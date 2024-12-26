// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxDAO {

    address public owner;
    uint256 public proposalCount;  // تعداد پیشنهادات
    uint256 public minimumVotes;  // حداقل رای‌ها برای تایید یک پیشنهاد

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 voteCount;
        bool executed;
        mapping(address => bool) votes;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can create proposals");
        _;
    }

    modifier onlyProposer(uint256 proposalId) {
        require(msg.sender == proposals[proposalId].proposer, "Only proposer can execute the proposal");
        _;
    }

    constructor(uint256 _minimumVotes) {
        owner = msg.sender;
        minimumVotes = _minimumVotes;
    }

    // تابع برای ایجاد پیشنهاد جدید
    function createProposal(string calldata description) external onlyOwner {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.voteCount = 0;
        newProposal.executed = false;

        emit ProposalCreated(proposalCount, msg.sender, description);
    }

    // تابع برای رای دادن به یک پیشنهاد
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.executed == false, "Proposal already executed");
        require(proposal.votes[msg.sender] == false, "You have already voted");

        proposal.votes[msg.sender] = true;

        if (support) {
            proposal.voteCount++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    // تابع برای اجرای یک پیشنهاد پس از تایید
    function executeProposal(uint256 proposalId) external onlyProposer(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.voteCount >= minimumVotes, "Not enough votes to execute proposal");
        require(proposal.executed == false, "Proposal already executed");

        proposal.executed = true;

        // اینجا می‌توانید کد اجرایی برای پیشنهادات تایید شده را اضافه کنید

        emit ProposalExecuted(proposalId);
    }

    // تابع برای مشاهده تعداد رای‌های یک پیشنهاد
    function getVoteCount(uint256 proposalId) external view returns (uint256) {
        return proposals[proposalId].voteCount;
    }

    // تابع برای مشاهده جزئیات یک پیشنهاد
    function getProposal(uint256 proposalId) external view returns (address proposer, string memory description, uint256 voteCount, bool executed) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.proposer, proposal.description, proposal.voteCount, proposal.executed);
    }
}
