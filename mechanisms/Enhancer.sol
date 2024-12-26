// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// Main Contract
contract OrumyxGovernance {
    // Variables
    IERC20 public orumyxToken; // Token contract
    address public admin; // Contract admin
    address public pendingAdmin; // For admin updates
    uint256 public dynamicFee = 1; // Default fee 1%

    // Proposal Details
    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 endTime;
    }

    // Reward Pools
    struct RewardPool {
        uint256 totalStaked;
        mapping(address => uint256) stakes;
        mapping(address => uint256) rewards;
        uint256 rewardRate;
    }

    // Variables for Sybil Resistance and Proposals
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(address => bool) public voters;
    uint256 public voterStakeRequirement = 100 * 1e18; // Min stake to vote
    uint256 public proposalFee = 10 * 1e18; // Proposal creation fee

    // Reward Pool
    RewardPool public rewardPool;

    // Events
    event ProposalCreated(uint256 proposalId, string description, uint256 endTime);
    event Voted(uint256 proposalId, address voter, bool vote);
    event Executed(uint256 proposalId);
    event RewardDistributed(address indexed user, uint256 reward);
    event DynamicFeeUpdated(uint256 newFee);
    event AdminTransferProposed(address pendingAdmin);
    event AdminTransferred(address newAdmin);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyVoter() {
        require(voters[msg.sender] || rewardPool.stakes[msg.sender] >= voterStakeRequirement, "Not eligible to vote");
        _;
    }

    // Constructor
    constructor(address _orumyxToken) {
        admin = msg.sender;
        orumyxToken = IERC20(_orumyxToken);
    }

    // Governance Upgradability - Transfer Admin Role
    function proposeAdminTransfer(address newAdmin) external onlyAdmin {
        pendingAdmin = newAdmin;
        emit AdminTransferProposed(newAdmin);
    }

    function acceptAdminTransfer() external {
        require(msg.sender == pendingAdmin, "Not pending admin");
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit AdminTransferred(admin);
    }

    // Anti-Sybil Voting - Stake Requirement
    function enableVoter(address user) external onlyAdmin {
        require(rewardPool.stakes[user] >= voterStakeRequirement, "Stake requirement not met");
        voters[user] = true;
    }

    // Proposal Creation
    function createProposal(string memory description, uint256 duration) external {
        require(orumyxToken.transferFrom(msg.sender, address(this), proposalFee), "Fee required");
        uint256 endTime = block.timestamp + duration;

        proposals[proposalCount] = Proposal(description, 0, 0, false, endTime);
        emit ProposalCreated(proposalCount, description, endTime);
        proposalCount++;
    }

    // Voting
    function vote(uint256 proposalId, bool support) external onlyVoter {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.endTime, "Voting ended");
        require(!proposal.executed, "Already executed");

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit Voted(proposalId, msg.sender, support);
    }

    // Execute Proposal
    function executeProposal(uint256 proposalId) external onlyAdmin {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        emit Executed(proposalId);
    }

    // Automated Reward Distribution via Yield Farming
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake zero");
        rewardPool.totalStaked += amount;
        rewardPool.stakes[msg.sender] += amount;
        orumyxToken.transferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount) external {
        require(rewardPool.stakes[msg.sender] >= amount, "Insufficient stake");
        rewardPool.totalStaked -= amount;
        rewardPool.stakes[msg.sender] -= amount;
        orumyxToken.transfer(msg.sender, amount);
    }

    function distributeRewards() external onlyAdmin {
        for (uint256 i = 0; i < proposalCount; i++) {
            Proposal storage proposal = proposals[i];
            if (proposal.executed) {
                for (address user : voters) {
                    uint256 reward = (rewardPool.stakes[user] * rewardPool.rewardRate) / 100;
                    orumyxToken.transfer(user, reward);
                    emit RewardDistributed(user, reward);
                }
            }
        }
    }

    // Dynamic Fee Adjustment
    function updateDynamicFee(uint256 newFee) external onlyAdmin {
        require(newFee <= 5, "Fee cannot exceed 5%");
        dynamicFee = newFee;
        emit DynamicFeeUpdated(newFee);
    }

    // Transparency & Audit Logs
    function getProposalDetails(uint256 proposalId)
        external
        view
        returns (
            string memory description,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed,
            uint256 endTime
        )
    {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.executed, proposal.endTime);
    }

    function getStakeDetails(address user) external view returns (uint256 stakeAmount, uint256 rewards) {
        return (rewardPool.stakes[user], rewardPool.rewards[user]);
    }
}
