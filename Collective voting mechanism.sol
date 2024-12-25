// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxVoting {

    address public owner;
    uint256 public votingPeriod;                // مدت زمان برای رای‌گیری
    uint256 public currentVotingId;             // شناسه رای‌گیری کنونی
    mapping(uint256 => Voting) public votes;    // نقشه‌ای برای ذخیره‌سازی اطلاعات رای‌گیری
    mapping(address => mapping(uint256 => bool)) public hasVoted; // ثبت رای‌دهندگان

    struct Voting {
        uint256 id;
        address proposer;
        string proposalDescription;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTime;
        bool isFinished;
    }

    event ProposalCreated(uint256 indexed votingId, address indexed proposer, string proposalDescription);
    event Voted(uint256 indexed votingId, address indexed voter, bool vote);
    event VotingClosed(uint256 indexed votingId, bool passed);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can initiate voting");
        _;
    }

    modifier onlyDuringVotingPeriod(uint256 votingId) {
        require(block.timestamp < votes[votingId].endTime, "Voting period has ended");
        _;
    }

    modifier onlyAfterVotingPeriod(uint256 votingId) {
        require(block.timestamp >= votes[votingId].endTime, "Voting period has not ended yet");
        _;
    }

    constructor(uint256 _votingPeriod) {
        owner = msg.sender;
        votingPeriod = _votingPeriod;  // مدت زمان رای‌گیری (مثلا 1 هفته)
    }

    // تابع برای ایجاد یک پیشنهاد جدید
    function createProposal(string memory description) external onlyOwner returns (uint256) {
        currentVotingId++;
        uint256 votingId = currentVotingId;

        votes[votingId] = Voting({
            id: votingId,
            proposer: msg.sender,
            proposalDescription: description,
            yesVotes: 0,
            noVotes: 0,
            endTime: block.timestamp + votingPeriod,
            isFinished: false
        });

        emit ProposalCreated(votingId, msg.sender, description);
        return votingId;
    }

    // تابع برای رای دادن به یک پیشنهاد
    function vote(uint256 votingId, bool support) external onlyDuringVotingPeriod(votingId) {
        require(!hasVoted[msg.sender][votingId], "You have already voted");
        
        hasVoted[msg.sender][votingId] = true;
        
        if (support) {
            votes[votingId].yesVotes++;
        } else {
            votes[votingId].noVotes++;
        }

        emit Voted(votingId, msg.sender, support);
    }

    // تابع برای بستن رای‌گیری و اعلام نتیجه
    function closeVoting(uint256 votingId) external onlyAfterVotingPeriod(votingId) {
        require(!votes[votingId].isFinished, "Voting has already been closed");

        votes[votingId].isFinished = true;

        bool passed = votes[votingId].yesVotes > votes[votingId].noVotes;
        emit VotingClosed(votingId, passed);
        
        // در صورتی که رای به تصویب رسیده باشد، اقدامات لازم برای پیاده‌سازی پیشنهاد انجام می‌شود
        if (passed) {
            implementProposal(votingId);
        }
    }

    // تابع برای پیاده‌سازی پیشنهاد (در اینجا پیاده‌سازی پیشنهادی است که می‌تواند به تغییرات مختلفی مانند تغییر ذخایر، سیاست‌های مالی و غیره اشاره کند)
    function implementProposal(uint256 votingId) internal {
        // در اینجا اقداماتی برای پیاده‌سازی پیشنهاد انجام می‌شود
        // مانند به‌روزرسانی ذخایر، تغییرات در سیاست‌های شبکه و غیره
        // به عنوان مثال:
        // updateOilReserves(address(0), 5000); 
    }
}
