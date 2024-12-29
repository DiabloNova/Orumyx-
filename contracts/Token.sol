// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Orumyx {
    // Basic Information
    string public name = "Orumyx";
    string public symbol = "ORX";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1_000_000_000 * (10 ** uint256(decimals)); // 1 billion tokens

    // Address Balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Governance Variables
    uint256 public governanceSupply = 2_250_000_000 * (10 ** uint256(decimals)); // 225% Governance Tokens
    uint256 public circulatingSupply;

    // Owner and DAO Governance
    address public owner;
    mapping(address => bool) public isGovernance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event GovernanceAdded(address indexed account);
    event GovernanceRemoved(address indexed account);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    modifier onlyGovernance() {
        require(isGovernance[msg.sender], "Only governance allowed");
        _;
    }

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        circulatingSupply = totalSupply; // Set circulating supply to initial total
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ERC-20 Transfer
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // ERC-20 Approve
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // ERC-20 Transfer From
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Governance Functions
    function addGovernance(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        isGovernance[account] = true;
        emit GovernanceAdded(account);
    }

    function removeGovernance(address account) external onlyOwner {
        require(isGovernance[account], "Not a governance account");
        isGovernance[account] = false;
        emit GovernanceRemoved(account);
    }

    // Minting Tokens (Only Governance)
    function mint(address to, uint256 amount) external onlyGovernance {
        require(governanceSupply >= amount, "Exceeds governance reserve");
        governanceSupply -= amount;
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    // Burning Tokens (Deflation Mechanism)
    function burn(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    // Governance Voting Power
    function votingPower(address account) external view returns (uint256) {
        return balanceOf[account];
    }

    // Reserve Management (Simple Collateralization Check)
    function collateralRatio(uint256 reserveValue) external view returns (uint256) {
        require(reserveValue > 0, "Invalid reserve value");
        return (reserveValue * 1e18) / circulatingSupply;
    }

    // DAO Proposal and Voting (Basic Example)
    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    Proposal[] public proposals;

    function createProposal(string memory description) external onlyGovernance {
        proposals.push(Proposal({
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        }));
    }

    function voteOnProposal(uint256 proposalId, bool support) external onlyGovernance {
        require(proposalId < proposals.length, "Invalid proposal");
        require(!proposals[proposalId].executed, "Proposal already executed");
        if (support) {
            proposals[proposalId].votesFor += balanceOf[msg.sender];
        } else {
            proposals[proposalId].votesAgainst += balanceOf[msg.sender];
        }
    }

    function executeProposal(uint256 proposalId) external onlyGovernance {
        require(proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Already executed");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.executed = true;
        } else {
            proposal.executed = false;
        }
    }
}

