// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MultiSigTreasury {
    // Governance and Token
    IERC20 public orumyxToken;

    // Treasury Owners
    address[] public owners; // List of multi-sig owners
    mapping(address => bool) public isOwner; // Ownership verification
    uint256 public requiredApprovals; // Number of required approvals

    // Transaction Structure
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 approvals;
    }

    mapping(uint256 => Transaction) public transactions; // Transactions list
    mapping(uint256 => mapping(address => bool)) public approvals; // Approval tracking
    uint256 public transactionCount; // Transaction counter

    // Events
    event Deposit(address indexed sender, uint256 value);
    event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value);
    event TransactionApproved(address indexed owner, uint256 indexed txId);
    event TransactionExecuted(uint256 indexed txId);
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event RequiredApprovalsChanged(uint256 requiredApprovals);

    // Modifiers
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < transactionCount, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }

    modifier notApproved(uint256 txId) {
        require(!approvals[txId][msg.sender], "Transaction already approved");
        _;
    }

    // Constructor
    constructor(address[] memory _owners, uint256 _requiredApprovals, address _orumyxToken) {
        require(_owners.length > 0, "Owners required");
        require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, "Invalid required approvals");
        require(_orumyxToken != address(0), "Invalid token address");

        orumyxToken = IERC20(_orumyxToken);

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "Owner already added");

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    // Deposit ORX Tokens to Treasury
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        orumyxToken.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    // Submit a Transaction Proposal
    function submitTransaction(address to, uint256 value) external onlyOwner {
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Value must be greater than zero");

        transactions[transactionCount] = Transaction({
            to: to,
            value: value,
            executed: false,
            approvals: 0
        });

        emit TransactionSubmitted(transactionCount, to, value);
        transactionCount++;
    }

    // Approve a Transaction
    function approveTransaction(uint256 txId)
        external
        onlyOwner
        txExists(txId)
        notExecuted(txId)
        notApproved(txId)
    {
        approvals[txId][msg.sender] = true;
        transactions[txId].approvals++;

        emit TransactionApproved(msg.sender, txId);

        if (transactions[txId].approvals >= requiredApprovals) {
            executeTransaction(txId);
        }
    }

    // Execute a Transaction
    function executeTransaction(uint256 txId)
        public
        onlyOwner
        txExists(txId)
        notExecuted(txId)
    {
        Transaction storage txn = transactions[txId];
        require(txn.approvals >= requiredApprovals, "Not enough approvals");

        txn.executed = true;
        orumyxToken.transfer(txn.to, txn.value);

        emit TransactionExecuted(txId);
    }

    // Add an Owner (Requires Approval)
    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        require(!isOwner[newOwner], "Already an owner");

        isOwner[newOwner] = true;
        owners.push(newOwner);

        emit OwnerAdded(newOwner);
    }

    // Remove an Owner (Requires Approval)
    function removeOwner(address owner) external onlyOwner {
        require(isOwner[owner], "Not an owner");
        require(owners.length > requiredApprovals, "Cannot remove owner");

        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }

        emit OwnerRemoved(owner);
    }

    // Update Required Approvals
    function updateRequiredApprovals(uint256 _requiredApprovals) external onlyOwner {
        require(_requiredApprovals > 0 && _requiredApprovals <= owners.length, "Invalid required approvals");
        requiredApprovals = _requiredApprovals;
        emit RequiredApprovalsChanged(_requiredApprovals);
    }

    // View Functions
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransaction(uint256 txId)
        external
        view
        returns (address to, uint256 value, bool executed, uint256 approvals)
    {
        Transaction memory txn = transactions[txId];
        return (txn.to, txn.value, txn.executed, txn.approvals);
    }

    function isApproved(uint256 txId, address owner) external view returns (bool) {
        return approvals[txId][owner];
    }

    function getTreasuryBalance() external view returns (uint256) {
        return orumyxToken.balanceOf(address(this));
    }
}
