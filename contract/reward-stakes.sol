// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxDAO {

    // Governance parameters
    address public owner;
    address public orumyxTokenAddress;
    OrumyxToken public orumyxToken;
    mapping(address => uint256) public governanceVotes;
    uint256 public totalVotes;

    // Governance events
    event ProposalCreated(address indexed proposer, string proposalDescription, uint256 proposalId);
    event Voted(address indexed voter, uint256 proposalId, bool inFavor);

    // Proposal structure
    struct Proposal {
        string description;
        uint256 voteCountInFavor;
        uint256 voteCountAgainst;
        bool executed;
    }

    // List of proposals
    Proposal[] public proposals;

    constructor(address _orumyxTokenAddress) {
        orumyxTokenAddress = _orumyxTokenAddress;
        orumyxToken = OrumyxToken(_orumyxTokenAddress);
        owner = msg.sender;
    }

    // Function to create a governance proposal
    function createProposal(string memory _description) external returns (uint256 proposalId) {
        require(orumyxToken.balanceOf(msg.sender) > 0, "You must own ORX tokens to create a proposal");

        Proposal memory newProposal = Proposal({
            description: _description,
            voteCountInFavor: 0,
            voteCountAgainst: 0,
            executed: false
        });

        proposals.push(newProposal);
        proposalId = proposals.length - 1;
        
        emit ProposalCreated(msg.sender, _description, proposalId);
    }

    // Function for token holders to vote on proposals
    function voteOnProposal(uint256 _proposalId, bool _inFavor) external {
        require(_proposalId < proposals.length, "Proposal does not exist");
        require(orumyxToken.balanceOf(msg.sender) > 0, "You must own ORX tokens to vote");

        Proposal storage proposal = proposals[_proposalId];
        
        // Ensure user can vote only once
        require(governanceVotes[msg.sender] == 0, "You have already voted on this proposal");

        uint256 voteWeight = orumyxToken.balanceOf(msg.sender);

        // Record the vote and update the proposal's vote count
        if (_inFavor) {
            proposal.voteCountInFavor += voteWeight;
        } else {
            proposal.voteCountAgainst += voteWeight;
        }

        governanceVotes[msg.sender] = _proposalId; // Track user votes

        emit Voted(msg.sender, _proposalId, _inFavor);
    }

    // Function to execute a proposal after voting concludes
    function executeProposal(uint256 _proposalId) external {
        require(_proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[_proposalId];

        // Ensure proposal has enough votes and hasn't been executed yet
        require(!proposal.executed, "Proposal has already been executed");
        require(proposal.voteCountInFavor > proposal.voteCountAgainst, "Proposal did not pass");

        // Execute the proposal logic here (depends on the specific proposal)
        // For example, transferring funds, modifying system parameters, etc.

        proposal.executed = true;

        // Additional actions based on the proposal logic can be added here
    }

    // Function to get the total number of proposals
    function getTotalProposals() external view returns (uint256) {
        return proposals.length;
    }

    // Function to get the details of a specific proposal
    function getProposalDetails(uint256 _proposalId) external view returns (string memory description, uint256 voteCountInFavor, uint256 voteCountAgainst, bool executed) {
        require(_proposalId < proposals.length, "Proposal does not exist");
        Proposal storage proposal = proposals[_proposalId];
        
        return (proposal.description, proposal.voteCountInFavor, proposal.voteCountAgainst, proposal.executed);
    }
}

contract OrumyxRewardSystem {

    address public orumyxTokenAddress;
    OrumyxToken public orumyxToken;

    mapping(address => uint256) public rewards;
    uint256 public totalRewards;
    uint256 public rewardPool;

    // Reward distribution events
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardPoolUpdated(uint256 newRewardPoolAmount);

    constructor(address _orumyxTokenAddress) {
        orumyxTokenAddress = _orumyxTokenAddress;
        orumyxToken = OrumyxToken(_orumyxTokenAddress);
    }

    // Function to deposit rewards into the reward pool (only callable by DAO/governance)
    function depositRewards(uint256 _amount) external {
        require(orumyxToken.balanceOf(msg.sender) >= _amount, "Insufficient ORX balance");
        
        orumyxToken.transferFrom(msg.sender, address(this), _amount);
        rewardPool += _amount;

        emit RewardPoolUpdated(rewardPool);
    }

    // Function to distribute rewards to users (can be triggered by DAO/governance)
    function distributeRewards(address[] calldata users, uint256[] calldata amounts) external {
        require(users.length == amounts.length, "Users and amounts length mismatch");

        for (uint256 i = 0; i < users.length; i++) {
            rewards[users[i]] += amounts[i];
            totalRewards += amounts[i];
        }

        emit RewardPoolUpdated(rewardPool);
    }

    // Function for users to claim their rewards
    function claimReward() external {
        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount > 0, "No rewards available to claim");

        rewards[msg.sender] = 0;

        orumyxToken.transfer(msg.sender, rewardAmount);

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    // Function to get the reward pool status
    function getRewardPoolStatus() external view returns (uint256, uint256) {
        return (rewardPool, totalRewards);
    }

    // Function to get the reward balance for a specific user
    function getUserRewardBalance(address user) external view returns (uint256) {
        return rewards[user];
    }
}

