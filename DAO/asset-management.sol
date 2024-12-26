// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReportingAndTransparency {
    address public owner;
    uint256 public totalSupply;
    uint256 public totalTransactions;
    uint256 public totalFees;
    mapping(address => uint256) public balances;

    event TransactionExecuted(address indexed from, address indexed to, uint256 amount);
    event BalanceUpdated(address indexed user, uint256 newBalance);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply;
    }

    // Function to transfer tokens between users
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        totalTransactions += 1;

        emit TransactionExecuted(msg.sender, to, amount);
        emit BalanceUpdated(msg.sender, balances[msg.sender]);
        emit BalanceUpdated(to, balances[to]);
    }

    // Function to view the balance of a specific user
    function viewBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    // Function to get the total fees collected by the system
    function getTotalFees() public view returns (uint256) {
        return totalFees;
    }

    // Function to get the total number of transactions
    function getTotalTransactions() public view returns (uint256) {
        return totalTransactions;
    }

    // Function to update the system's total supply
    function updateSupply(uint256 newSupply) public onlyOwner {
        totalSupply = newSupply;
    }

    // Function to get the total supply of tokens in the system
    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecurityAndFundProtection {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => bool) public isFrozen;
    
    event FundsFrozen(address indexed user);
    event FundsUnfrozen(address indexed user);
    event UnauthorizedAccessAttempt(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier notFrozen(address user) {
        require(!isFrozen[user], "User's funds are frozen");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to freeze a user's funds in case of suspicious activity
    function freezeFunds(address user) public onlyOwner {
        require(user != address(0), "Invalid address");
        isFrozen[user] = true;
        emit FundsFrozen(user);
    }

    // Function to unfreeze a user's funds
    function unfreezeFunds(address user) public onlyOwner {
        require(user != address(0), "Invalid address");
        isFrozen[user] = false;
        emit FundsUnfrozen(user);
    }

    // Function to transfer tokens with protection against frozen accounts
    function transfer(address to, uint256 amount) public notFrozen(msg.sender) notFrozen(to) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    // Function to deposit funds into the system
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        balances[msg.sender] += amount;
    }

    // Function to withdraw funds from the system
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
    }

    // Function to view the balance of a specific user
    function viewBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    // Function to get the owner of the contract
    function getOwner() public view returns (address) {
        return owner;
    }

    // Function to report unauthorized access attempts
    function reportUnauthorizedAccess() public {
        emit UnauthorizedAccessAttempt(msg.sender);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IncidentManagementAndForceMajeure {
    address public owner;
    bool public isPaused = false;
    uint256 public incidentTimestamp;
    mapping(address => uint256) public emergencyBalances;
    
    event SystemPaused(address indexed owner);
    event SystemResumed(address indexed owner);
    event IncidentOccurred(address indexed owner, uint256 timestamp);
    event EmergencyWithdrawal(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier systemNotPaused() {
        require(!isPaused, "System is paused due to emergency");
        _;
    }

    modifier systemPaused() {
        require(isPaused, "System is not paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to pause the system in case of emergency or force majeure
    function pauseSystem() public onlyOwner {
        isPaused = true;
        incidentTimestamp = block.timestamp;
        emit SystemPaused(owner);
        emit IncidentOccurred(owner, incidentTimestamp);
    }

    // Function to resume the system after an incident or force majeure event is resolved
    function resumeSystem() public onlyOwner systemPaused {
        isPaused = false;
        emit SystemResumed(owner);
    }

    // Emergency withdrawal function to allow users to withdraw a limited amount during an incident
    function emergencyWithdraw(uint256 amount) public systemPaused {
        require(emergencyBalances[msg.sender] >= amount, "Insufficient balance for emergency withdrawal");
        emergencyBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit EmergencyWithdrawal(msg.sender, amount);
    }

    // Function to deposit funds during a normal operation
    function deposit(uint256 amount) public systemNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        emergencyBalances[msg.sender] += amount;
    }

    // Function to view the emergency balance of a specific user
    function viewEmergencyBalance(address user) public view returns (uint256) {
        return emergencyBalances[user];
    }

    // Function to trigger an emergency situation manually (for testing or other purposes)
    function triggerEmergency() public onlyOwner {
        pauseSystem();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RewardsAndIncentives {
    address public owner;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public rewards;
    uint256 public rewardPool;
    uint256 public rewardRate;  // Percentage of reward pool to distribute to users

    event RewardDistributed(address indexed user, uint256 amount);
    event RewardPoolUpdated(uint256 newRewardPool);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier hasRewards() {
        require(rewards[msg.sender] > 0, "No rewards available for you");
        _;
    }

    constructor(uint256 _totalSupply, uint256 _rewardRate) {
        owner = msg.sender;
        totalSupply = _totalSupply;
        rewardRate = _rewardRate;
        rewardPool = totalSupply / 10;  // 10% of total supply is reserved for rewards
    }

    // Function to deposit tokens into the reward pool
    function depositToRewardPool(uint256 amount) public onlyOwner {
        require(amount <= balances[msg.sender], "Insufficient balance for deposit");
        balances[msg.sender] -= amount;
        rewardPool += amount;
        emit RewardPoolUpdated(rewardPool);
    }

    // Function to distribute rewards based on the reward rate
    function distributeRewards() public onlyOwner {
        require(rewardPool > 0, "Reward pool is empty");
        uint256 totalEligibleUsers = 0;
        for (uint256 i = 0; i < totalSupply; i++) {
            address user = address(i);  // Example logic, could be replaced by actual user tracking
            if (balances[user] > 0) {
                totalEligibleUsers++;
            }
        }
        
        uint256 rewardPerUser = (rewardPool * rewardRate) / 100;
        
        for (uint256 i = 0; i < totalSupply; i++) {
            address user = address(i);
            if (balances[user] > 0) {
                rewards[user] += rewardPerUser;
                emit RewardDistributed(user, rewardPerUser);
            }
        }
    }

    // Function for users to claim their rewards
    function claimRewards() public hasRewards {
        uint256 rewardAmount = rewards[msg.sender];
        rewards[msg.sender] = 0;  // Reset user's reward balance
        payable(msg.sender).transfer(rewardAmount);
    }

    // Function to allow users to deposit their own tokens
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        balances[msg.sender] += amount;
    }

    // Function to allow users to withdraw their tokens
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance for withdrawal");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MonitoringAndReporting {
    address public owner;
    uint256 public totalTransactions;
    mapping(address => uint256) public transactionCount;
    mapping(address => uint256) public totalSpent;
    mapping(address => uint256) public totalReceived;
    uint256 public totalFundsRaised;
    uint256 public totalRewardsDistributed;

    event TransactionReported(address indexed user, uint256 amount, string transactionType);
    event FundRaised(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 amount);
    event Reporting(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier validUser() {
        require(transactionCount[msg.sender] > 0, "No transactions performed by user");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to report a new transaction
    function reportTransaction(address user, uint256 amount, string memory transactionType) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        
        totalTransactions++;
        transactionCount[user]++;
        if (keccak256(bytes(transactionType)) == keccak256(bytes("send"))) {
            totalSpent[user] += amount;
        } else if (keccak256(bytes(transactionType)) == keccak256(bytes("receive"))) {
            totalReceived[user] += amount;
        }

        emit TransactionReported(user, amount, transactionType);
    }

    // Function to raise funds and update the record
    function raiseFunds(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        totalFundsRaised += amount;
        emit FundRaised(msg.sender, amount);
    }

    // Function to distribute rewards and update records
    function distributeRewards(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        totalRewardsDistributed += amount;
        emit RewardsDistributed(amount);
    }

    // Function to get transaction reports
    function getTransactionReport(address user) public view validUser returns (uint256 spent, uint256 received, uint256 count) {
        spent = totalSpent[user];
        received = totalReceived[user];
        count = transactionCount[user];
    }

    // Function to get the overall fund raised and rewards distributed
    function getFundStatus() public view returns (uint256 fundsRaised, uint256 rewardsDistributed) {
        fundsRaised = totalFundsRaised;
        rewardsDistributed = totalRewardsDistributed;
    }

    // Function to allow the owner to generate custom reports for auditing and transparency
    function generateReport() public onlyOwner view returns (uint256 transactions, uint256 funds, uint256 rewards) {
        return (totalTransactions, totalFundsRaised, totalRewardsDistributed);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractManagement {
    address public owner;
    bool public contractActive;
    mapping(address => bool) public authorizedUpdaters;
    
    event ContractActivated(address indexed owner);
    event ContractDeactivated(address indexed owner);
    event ContractUpdated(address indexed updater, string updateDetails);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAuthorizedUpdaters() {
        require(authorizedUpdaters[msg.sender], "Not authorized to update the contract");
        _;
    }

    constructor() {
        owner = msg.sender;
        contractActive = true;
        authorizedUpdaters[msg.sender] = true; // The owner is initially authorized
    }

    // Function to activate the contract
    function activateContract() public onlyOwner {
        require(!contractActive, "Contract is already active");
        contractActive = true;
        emit ContractActivated(msg.sender);
    }

    // Function to deactivate the contract
    function deactivateContract() public onlyOwner {
        require(contractActive, "Contract is already inactive");
        contractActive = false;
        emit ContractDeactivated(msg.sender);
    }

    // Function to authorize a new updater
    function authorizeUpdater(address updater) public onlyOwner {
        authorizedUpdaters[updater] = true;
    }

    // Function to revoke an updater's authorization
    function revokeUpdater(address updater) public onlyOwner {
        authorizedUpdaters[updater] = false;
    }

    // Function to update the contract with new features or fixes
    function updateContract(string memory updateDetails) public onlyAuthorizedUpdaters {
        emit ContractUpdated(msg.sender, updateDetails);
    }

    // Function to check contract status
    function isContractActive() public view returns (bool) {
        return contractActive;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControl {
    address public owner;
    mapping(address => bool) public authorizedAddresses;
    mapping(address => uint256) public userBalances;
    
    event AccessGranted(address indexed user);
    event AccessRevoked(address indexed user);
    event DepositMade(address indexed user, uint256 amount);
    event WithdrawalMade(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedAddresses[msg.sender], "Not authorized to perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to grant access to an address
    function grantAccess(address user) public onlyOwner {
        authorizedAddresses[user] = true;
        emit AccessGranted(user);
    }

    // Function to revoke access from an address
    function revokeAccess(address user) public onlyOwner {
        authorizedAddresses[user] = false;
        emit AccessRevoked(user);
    }

    // Function to deposit funds into the contract
    function deposit(uint256 amount) public payable {
        require(msg.value == amount, "Deposit amount must match sent value");
        userBalances[msg.sender] += amount;
        emit DepositMade(msg.sender, amount);
    }

    // Function to withdraw funds from the contract
    function withdraw(uint256 amount) public {
        require(userBalances[msg.sender] >= amount, "Insufficient balance");
        userBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit WithdrawalMade(msg.sender, amount);
    }

    // Function to check balance of an address
    function checkBalance(address user) public view returns (uint256) {
        return userBalances[user];
    }

    // Function to check if an address is authorized
    function isAuthorized(address user) public view returns (bool) {
        return authorizedAddresses[user];
    }
}




