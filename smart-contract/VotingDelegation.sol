// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOrumyxToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract OrumyxGovernance {
    address public owner;
    IOrumyxToken public orumyxToken;
    
    mapping(address => address) public delegations;  // Address of the delegate
    mapping(address => uint256) public votingPower;  // Voting power of each address
    mapping(address => bool) public voted;  // Track if an address has voted
    
    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event DelegationUpdated(address indexed delegator, address indexed delegatee);
    event Voted(uint256 proposalId, address indexed voter, bool support);
    event ProposalCreated(uint256 proposalId, string description);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute");
        _;
    }

    constructor(address _orumyxTokenAddress) {
        orumyxToken = IOrumyxToken(_orumyxTokenAddress);
        owner = msg.sender;
    }

    // Function to delegate voting power to another address
    function delegateVotes(address delegatee) external {
        require(delegatee != msg.sender, "Cannot delegate to yourself");
        require(delegations[msg.sender] == address(0), "Already delegated");
        
        // Delegate the voting power
        delegations[msg.sender] = delegatee;
        emit DelegationUpdated(msg.sender, delegatee);
    }

    // Function to revoke delegated votes
    function revokeDelegation() external {
        require(delegations[msg.sender] != address(0), "No delegation to revoke");
        
        address previousDelegate = delegations[msg.sender];
        delegations[msg.sender] = address(0);
        emit DelegationUpdated(msg.sender, address(0));
    }

    // Function to create a new proposal
    function createProposal(string memory description) external onlyOwner {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.description = description;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;

        emit ProposalCreated(proposalCount, description);
    }

    // Function to vote on a proposal
    function voteOnProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal");

        // Get the voting power
        uint256 votingPower = getVotingPower(msg.sender);

        // Update the vote count
        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        // Mark as voted
        proposal.hasVoted[msg.sender] = true;
        voted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support);
    }

    // Function to get the effective voting power (consider delegation)
    function getVotingPower(address account) public view returns (uint256) {
        address delegatee = delegations[account];
        
        if (delegatee != address(0)) {
            return orumyxToken.balanceOf(delegatee);
        }
        
        return orumyxToken.balanceOf(account);
    }

    // Function to execute the proposal (can be expanded to perform actions)
    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        // Execute based on votes (for example purposes, only execute if majority agrees)
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.executed = true;
            // Implement proposal execution logic here (e.g., change some state or perform an action)
        }
    }
}