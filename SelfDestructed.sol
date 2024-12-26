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
    address public daoGovernance;         // DAO Governance address (who can trigger migration/self-destruct)
    address public newContractAddress;    // Address of the new contract in case of migration

    enum ActionType { FundTransfer, SmartContractUpdate, ContractInteraction, ExternalProtocolIntegration }

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
        ActionType actionType; // Type of action for execution
        address actionTarget; // Target address for action
        uint256 actionAmount; // Amount for the action (if relevant)
        bytes actionData;     // Additional data for smart contract updates or interactions
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes;
    mapping(address => uint256) public lastVoteUpdate;  // Track the last vote power change

    event ProposalCreated(uint256 proposalId, address proposer, string description, uint256 voteStart, uint256 voteEnd);
    event VoteCast(address voter, uint256 proposalId, bool support);
    event ProposalExecuted(uint256 proposalId, bool passed);
    event ProposalExpired(uint256 proposalId);
    event FeeTransferredToDAO(address from, uint256 amount);
    event ContractMigrated(address newContract);
    event ContractDestroyed(address selfDestructedBy);

    modifier onlyTokenHolders() {
        require(orumyxToken.balanceOf(msg.sender) > 0, "Must hold tokens to vote");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == daoGovernance, "Only governance can perform this action");
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
    function _transferWithFee(address sender, address recipient, uint256 amount) internal
