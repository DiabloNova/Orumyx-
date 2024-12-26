// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxGovernance {

    string public constant name = "Orumyx Governance";
    
    // The ORX token contract address
    address public orumyxTokenAddress;
    OrumyxToken public orumyxToken;

    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startBlock;
        uint256 endBlock;
        bool executed;
    }

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Mapping to track whether an address has voted on a proposal
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Total number of proposals
    uint256 public proposalCount;

    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(address indexed voter, uint256 indexed proposalId, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);

    constructor(address _orumyxTokenAddress) {
        orumyxTokenAddress = _orumyxTokenAddress;
        orumyxToken = OrumyxToken(_orumyxTokenAddress);
    }

    // Function to create a new proposal
    function createProposal(string memory _description, uint256 _durationBlocks) external returns (uint256) {
        uint256 proposalId = proposalCount;
        proposalCount++;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            startBlock: block.number,
            endBlock: block.number + _durationBlocks,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number >= proposal.startBlock, "Voting has not started yet");
        require(block.number <= proposal.endBlock, "Voting has ended");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted");

        uint256 voterStake = orumyxToken.balanceOf(msg.sender);
        require(voterStake > 0, "You must hold tokens to vote");

        if (_support) {
            proposal.votesFor += voterStake;
        } else {
            proposal.votesAgainst += voterStake;
        }

        hasVoted[_proposalId][msg.sender] = true;

        emit Voted(msg.sender, _proposalId, _support);
    }

    // Function to execute the proposal after voting ends
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.number > proposal.endBlock, "Voting has not ended yet");
        require(!proposal.executed, "Proposal already executed");

        bool passed = proposal.votesFor > proposal.votesAgainst;
        proposal.executed = true;

        emit ProposalExecuted(_proposalId, passed);

        if (passed) {
            // Execute the logic of the proposal (this can be customized)
            // For example, modifying tokenomics, governance changes, etc.
        }
    }

    // Function to get the details of a proposal
    function getProposalDetails(uint256 _proposalId) external view returns (string memory, uint256, uint256, uint256, uint256) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.startBlock,
            proposal.endBlock
        );
    }
}

contract OrumyxStaking {
    address public orumyxTokenAddress;
    OrumyxToken public orumyxToken;

    // Mapping to track staked balances
    mapping(address => uint256) public stakedBalances;

    // Mapping to track user rewards
    mapping(address => uint256) public userRewards;

    // Total staked amount in the pool
    uint256 public totalStaked;

    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor(address _orumyxTokenAddress) {
        orumyxTokenAddress = _orumyxTokenAddress;
        orumyxToken = OrumyxToken(_orumyxTokenAddress);
    }

    // Function to stake ORX tokens
    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(orumyxToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");

        // Transfer tokens to the contract
        orumyxToken.transferFrom(msg.sender, address(this), _amount);

        // Update staked balance and total staked
        stakedBalances[msg.sender] += _amount;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    // Function to unstake ORX tokens
    function unstake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(stakedBalances[msg.sender] >= _amount, "Insufficient staked balance");

        // Update staked balance and total staked
        stakedBalances[msg.sender] -= _amount;
        totalStaked -= _amount;

        // Transfer tokens back to the user
        orumyxToken.transfer(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
    }

    // Function to calculate and distribute staking rewards
    function calculateRewards(address _user) public view returns (uint256) {
        uint256 userShare = stakedBalances[_user] * 100 / totalStaked;
        uint256 rewardAmount = userShare * totalStaked / 100; // Reward proportional to staked amount
        return rewardAmount;
    }

    // Function to claim staking rewards
    function claimRewards() external {
        uint256 reward = calculateRewards(msg.sender);
        require(reward > 0, "No rewards available");

        // Transfer rewards to the user
        orumyxToken.transfer(msg.sender, reward);

        emit RewardsClaimed(msg.sender, reward);
    }
}
