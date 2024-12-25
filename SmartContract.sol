// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxLiquidityPool {

    address public owner;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidityProviders;
    mapping(address => uint256) public liquidityWithdrawals;

    event LiquidityProvided(address indexed provider, uint256 amount);
    event LiquidityWithdrawn(address indexed provider, uint256 amount);
    event LiquidityPoolUpdated(uint256 totalLiquidity);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier hasLiquidity(address provider) {
        require(liquidityProviders[provider] > 0, "No liquidity found for this provider");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalLiquidity = 0;
    }

    // تابع برای اضافه کردن نقدینگی به استخر
    function provideLiquidity() external payable {
        require(msg.value > 0, "Liquidity must be greater than zero");
        liquidityProviders[msg.sender] += msg.value;
        totalLiquidity += msg.value;
        emit LiquidityProvided(msg.sender, msg.value);
        emit LiquidityPoolUpdated(totalLiquidity);
    }

    // تابع برای برداشت نقدینگی از استخر
    function withdrawLiquidity(uint256 amount) external hasLiquidity(msg.sender) {
        require(amount <= liquidityProviders[msg.sender], "Insufficient liquidity to withdraw");
        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;
        payable(msg.sender).transfer(amount);
        emit LiquidityWithdrawn(msg.sender, amount);
        emit LiquidityPoolUpdated(totalLiquidity);
    }

    // تابع برای مشاهده نقدینگی تأمین شده توسط یک سرمایه‌گذار
    function getLiquidity(address provider) external view returns (uint256) {
        return liquidityProviders[provider];
    }

    // تابع برای مشاهده کل نقدینگی استخر
    function getTotalLiquidity() external view returns (uint256) {
        return totalLiquidity;
    }
}

contract OrumyxTokenManagement {

    string public name = "Orumyx Token";
    string public symbol = "ORUMYX";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensBurned(address indexed burner, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier validAddress(address addr) {
        require(addr != address(0), "Invalid address");
        _;
    }

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // تابع انتقال توکن
    function transfer(address to, uint256 amount) external validAddress(to) returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // تابع تایید مجوز انتقال به شخص دیگر
    function approve(address spender, uint256 amount) external validAddress(spender) returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // تابع انتقال از یک آدرس به آدرس دیگر با مجوز
    function transferFrom(address from, address to, uint256 amount) external validAddress(to) returns (bool) {
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Allowance exceeded");
        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // تابع سوزاندن توکن
    function burn(uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit TokensBurned(msg.sender, amount);
        return true;
    }

    // تابع مشاهده موجودی یک آدرس
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // تابع مشاهده مقدار مجوز انتقال
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }
}


contract OrumyxRewardAndFeeSystem {

    address public owner;
    uint256 public feePercentage; // درصد کارمزد
    uint256 public rewardPercentage; // درصد پاداش

    mapping(address => uint256) public rewards;

    event FeeCollected(address indexed from, uint256 amount);
    event RewardDistributed(address indexed to, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(uint256 _feePercentage, uint256 _rewardPercentage) {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        require(_rewardPercentage <= 100, "Reward percentage cannot exceed 100%");
        owner = msg.sender;
        feePercentage = _feePercentage;
        rewardPercentage = _rewardPercentage;
    }

    // تابع برای انتقال توکن با اعمال کارمزد و پاداش
    function transferWithFeeAndReward(address to, uint256 amount) external returns (bool) {
        uint256 feeAmount = (amount * feePercentage) / 100;
        uint256 rewardAmount = (amount * rewardPercentage) / 100;
        uint256 finalAmount = amount - feeAmount;

        // انتقال کارمزد به حساب قرارداد
        payable(owner).transfer(feeAmount);
        emit FeeCollected(msg.sender, feeAmount);

        // انتقال پاداش به گیرنده
        rewards[to] += rewardAmount;
        emit RewardDistributed(to, rewardAmount);

        // انتقال مبلغ نهایی به گیرنده
        payable(to).transfer(finalAmount);

        return true;
    }

    // تابع برای برداشت پاداش توسط گیرندگان
    function withdrawReward() external returns (bool) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to withdraw");

        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(reward);
        return true;
    }

    // تابع برای تنظیم درصد کارمزد
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        feePercentage = _feePercentage;
    }

    // تابع برای تنظیم درصد پاداش
    function setRewardPercentage(uint256 _rewardPercentage) external onlyOwner {
        require(_rewardPercentage <= 100, "Reward percentage cannot exceed 100%");
        rewardPercentage = _rewardPercentage;
    }
}


contract OrumyxCashReserve {

    address public owner;
    uint256 public reserveBalance;
    uint256 public withdrawalLimit;
    
    event ReserveDeposited(address indexed from, uint256 amount);
    event ReserveWithdrawn(address indexed to, uint256 amount);
    event ReserveLimitUpdated(uint256 newLimit);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than zero");
        _;
    }

    constructor(uint256 _withdrawalLimit) {
        owner = msg.sender;
        withdrawalLimit = _withdrawalLimit;
        reserveBalance = 0;
    }

    // تابع برای واریز وجه به ذخایر نقدی
    function depositReserve(uint256 amount) external payable validAmount(amount) {
        require(msg.value == amount, "Incorrect value sent");
        reserveBalance += amount;
        emit ReserveDeposited(msg.sender, amount);
    }

    // تابع برای برداشت وجه از ذخایر نقدی
    function withdrawReserve(uint256 amount) external onlyOwner validAmount(amount) {
        require(amount <= reserveBalance, "Insufficient reserve balance");
        require(amount <= withdrawalLimit, "Exceeds withdrawal limit");

        reserveBalance -= amount;
        payable(owner).transfer(amount);
        emit ReserveWithdrawn(owner, amount);
    }

    // تابع برای تنظیم حد برداشت از ذخایر
    function setWithdrawalLimit(uint256 newLimit) external onlyOwner {
        withdrawalLimit = newLimit;
        emit ReserveLimitUpdated(newLimit);
    }

    // تابع برای مشاهده موجودی ذخایر نقدی
    function reserveBalanceOf() external view returns (uint256) {
        return reserveBalance;
    }

    // تابع برای مشاهده حد برداشت
    function getWithdrawalLimit() external view returns (uint256) {
        return withdrawalLimit;
    }
}


contract OrumyxVoting {

    address public owner;
    uint256 public votingDuration; // مدت زمان رای گیری به ثانیه
    uint256 public currentProposalId;

    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount;
        bool executed;
        uint256 endTime;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes;

    event ProposalCreated(uint256 id, string description);
    event Voted(address indexed voter, uint256 proposalId);
    event ProposalExecuted(uint256 proposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyBeforeEnd(uint256 proposalId) {
        require(block.timestamp < proposals[proposalId].endTime, "Voting has ended");
        _;
    }

    modifier onlyAfterEnd(uint256 proposalId) {
        require(block.timestamp >= proposals[proposalId].endTime, "Voting is still ongoing");
        _;
    }

    modifier hasNotVoted(uint256 proposalId) {
        require(!votes[msg.sender][proposalId], "You have already voted");
        _;
    }

    constructor(uint256 _votingDuration) {
        owner = msg.sender;
        votingDuration = _votingDuration;
        currentProposalId = 0;
    }

    // تابع برای ایجاد یک پیشنهاد جدید
    function createProposal(string memory description) external onlyOwner {
        currentProposalId++;
        uint256 endTime = block.timestamp + votingDuration;

        proposals[currentProposalId] = Proposal({
            id: currentProposalId,
            description: description,
            voteCount: 0,
            executed: false,
            endTime: endTime
        });

        emit ProposalCreated(currentProposalId, description);
    }

    // تابع برای رأی دادن به یک پیشنهاد
    function vote(uint256 proposalId) external onlyBeforeEnd(proposalId) hasNotVoted(proposalId) {
        proposals[proposalId].voteCount++;
        votes[msg.sender][proposalId] = true;

        emit Voted(msg.sender, proposalId);
    }

    // تابع برای اجرای یک پیشنهاد پس از اتمام رای گیری
    function executeProposal(uint256 proposalId) external onlyAfterEnd(proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");

        proposals[proposalId].executed = true;
        // اجرای عملیات مربوط به پیشنهاد در اینجا (میتوانید عملیات مختلف را بر اساس پیشنهاد انجام دهید)
        emit ProposalExecuted(proposalId);
    }

    // تابع برای مشاهده وضعیت یک پیشنهاد
    function getProposal(uint256 proposalId) external view returns (string memory description, uint256 voteCount, bool executed, uint256 endTime) {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.description, proposal.voteCount, proposal.executed, proposal.endTime);
    }
}


contract OrumyxReward {

    address public owner;
    uint256 public rewardRate; // نرخ پاداش به ازای هر واحد مشارکت
    mapping(address => uint256) public userContributions;
    mapping(address => uint256) public userRewards;

    event RewardIssued(address indexed user, uint256 amount);
    event ContributionRecorded(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier validContribution(uint256 amount) {
        require(amount > 0, "Contribution must be greater than zero");
        _;
    }

    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    // تابع برای ثبت مشارکت یک کاربر
    function recordContribution(address user, uint256 amount) external onlyOwner validContribution(amount) {
        userContributions[user] += amount;
        emit ContributionRecorded(user, amount);
    }

    // تابع برای محاسبه و ارسال پاداش به کاربر
    function issueReward(address user) external onlyOwner {
        uint256 contribution = userContributions[user];
        require(contribution > 0, "No contribution found for this user");

        uint256 rewardAmount = contribution * rewardRate;
        userRewards[user] += rewardAmount;
        payable(user).transfer(rewardAmount);
        emit RewardIssued(user, rewardAmount);
    }

    // تابع برای مشاهده میزان پاداش یک کاربر
    function getUserReward(address user) external view returns (uint256) {
        return userRewards[user];
    }

    // تابع برای تنظیم نرخ پاداش
    function setRewardRate(uint256 newRewardRate) external onlyOwner {
        rewardRate = newRewardRate;
    }
}


contract OrumyxCashReserve {

    address public owner;
    uint256 public totalCashReserve;
    uint256 public maxWithdrawalLimit; // حد برداشت حداکثری
    mapping(address => uint256) public userCashWithdrawals;

    event CashDeposited(address indexed user, uint256 amount);
    event CashWithdrawn(address indexed user, uint256 amount);
    event CashReserveUpdated(uint256 newTotalCashReserve);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier validWithdrawal(uint256 amount) {
        require(amount <= maxWithdrawalLimit, "Withdrawal exceeds the maximum allowed limit");
        require(amount <= totalCashReserve, "Not enough cash reserve");
        _;
    }

    modifier hasSufficientFunds(uint256 amount) {
        require(amount <= totalCashReserve, "Not enough funds in the reserve");
        _;
    }

    constructor(uint256 _maxWithdrawalLimit) {
        owner = msg.sender;
        maxWithdrawalLimit = _maxWithdrawalLimit;
        totalCashReserve = 0;
    }

    // تابع برای واریز وجه به ذخایر نقدی
    function depositCash(uint256 amount) external onlyOwner hasSufficientFunds(amount) {
        totalCashReserve += amount;
        emit CashDeposited(msg.sender, amount);
        emit CashReserveUpdated(totalCashReserve);
    }

    // تابع برای برداشت وجه از ذخایر نقدی
    function withdrawCash(uint256 amount) external validWithdrawal(amount) {
        totalCashReserve -= amount;
        userCashWithdrawals[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
        emit CashWithdrawn(msg.sender, amount);
        emit CashReserveUpdated(totalCashReserve);
    }

    // تابع برای تنظیم حد برداشت حداکثری
    function setMaxWithdrawalLimit(uint256 newLimit) external onlyOwner {
        maxWithdrawalLimit = newLimit;
    }

    // تابع برای مشاهده موجودی ذخایر نقدی
    function getCashReserve() external view returns (uint256) {
        return totalCashReserve;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxGovernance {

    address public owner;
    uint256 public proposalCount;
    uint256 public votingPeriod; // مدت زمان رای‌گیری
    uint256 public quorum; // حداقل تعداد آرا برای معتبر بودن
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public userVotes;

    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(address indexed voter, uint256 indexed proposalId, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);

    struct Proposal {
        string description;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 endTime;
        bool executed;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAfterVotingPeriod(uint256 proposalId) {
        require(block.timestamp > proposals[proposalId].endTime, "Voting period has not ended");
        _;
    }

    modifier validProposal(uint256 proposalId) {
        require(proposals[proposalId].endTime > block.timestamp, "Proposal expired or already executed");
        _;
    }

    modifier hasNotVoted(uint256 proposalId) {
        require(userVotes[msg.sender] != proposalId, "You have already voted on this proposal");
        _;
    }

    constructor(uint256 _votingPeriod, uint256 _quorum) {
        owner = msg.sender;
        votingPeriod = _votingPeriod;
        quorum = _quorum;
        proposalCount = 0;
    }

    // تابع برای ایجاد پیشنهاد
    function createProposal(string memory description) external onlyOwner {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: description,
            voteCountYes: 0,
            voteCountNo: 0,
            endTime: block.timestamp + votingPeriod,
            executed: false
        });
        emit ProposalCreated(proposalCount, description);
    }

    // تابع برای رای‌گیری
    function vote(uint256 proposalId, bool voteYes) external validProposal(proposalId) hasNotVoted(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        if (voteYes) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }

        userVotes[msg.sender] = proposalId;
        emit Voted(msg.sender, proposalId, voteYes);
    }

    // تابع برای اجرای پیشنهادات
    function executeProposal(uint256 proposalId) external onlyAfterVotingPeriod(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");

        if (proposal.voteCountYes >= quorum) {
            proposal.executed = true;
            // اقدامات اجرایی بر اساس پیشنهاد
            // برای مثال، تغییر پارامترها، انتقال توکن‌ها، و غیره.
            emit ProposalExecuted(proposalId);
        }
    }

    // تابع برای مشاهده تعداد آرا
    function getProposalVotes(uint256 proposalId) external view returns (uint256 yesVotes, uint256 noVotes) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.voteCountYes, proposal.voteCountNo);
    }

    // تابع برای تغییر مدت زمان رای‌گیری
    function setVotingPeriod(uint256 newVotingPeriod) external onlyOwner {
        votingPeriod = newVotingPeriod;
    }

    // تابع برای تغییر حداقل تعداد آرا
    function setQuorum(uint256 newQuorum) external onlyOwner {
        quorum = newQuorum;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxTransactions {
    
    address public owner;
    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier hasSufficientBalance(uint256 amount) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای واریز توکن به حساب
    function deposit() external payable {
        require(msg.value > 0, "Must send some ether");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // تابع برای برداشت توکن از حساب
    function withdraw(uint256 amount) external hasSufficientBalance(amount) {
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    // تابع برای انتقال توکن به آدرس دیگر
    function transfer(address to, uint256 amount) external hasSufficientBalance(amount) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    // تابع برای مشاهده موجودی یک حساب
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // تابع برای تغییر مالکیت
    function changeOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    // تابع برای برداشت تمامی موجودی به حساب مالک
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxLiquidityPool {
    
    address public owner;
    mapping(address => uint256) public liquidityProviders;
    uint256 public totalLiquidity;
    uint256 public poolFee = 1; // 1% fee for each transaction
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event LiquidityClaimed(address indexed provider, uint256 reward);
    event PoolFeeUpdated(uint256 newFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای افزودن نقدینگی به استخر
    function addLiquidity() external payable {
        require(msg.value > 0, "Must send some ether");
        liquidityProviders[msg.sender] += msg.value;
        totalLiquidity += msg.value;
        emit LiquidityAdded(msg.sender, msg.value);
    }

    // تابع برای برداشتن نقدینگی از استخر
    function removeLiquidity(uint256 amount) external {
        require(liquidityProviders[msg.sender] >= amount, "Insufficient liquidity");
        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;
        payable(msg.sender).transfer(amount);
        emit LiquidityRemoved(msg.sender, amount);
    }

    // تابع برای دریافت پاداش از استخر به نسبت سهم
    function claimLiquidityReward() external {
        uint256 providerLiquidity = liquidityProviders[msg.sender];
        require(providerLiquidity > 0, "No liquidity to claim reward");
        
        uint256 reward = (providerLiquidity * poolFee) / 100;
        payable(msg.sender).transfer(reward);
        emit LiquidityClaimed(msg.sender, reward);
    }

    // تابع برای به‌روزرسانی کارمزد استخر
    function updatePoolFee(uint256 newFee) external onlyOwner {
        require(newFee <= 5, "Fee cannot be more than 5%"); // Max 5% fee
        poolFee = newFee;
        emit PoolFeeUpdated(newFee);
    }

    // تابع برای مشاهده نقدینگی کل استخر
    function getTotalLiquidity() external view returns (uint256) {
        return totalLiquidity;
    }

    // تابع برای مشاهده سهم نقدینگی یک کاربر
    function getUserLiquidity(address user) external view returns (uint256) {
        return liquidityProviders[user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxStableToken {
    
    string public name = "Orumyx Stable Token";
    string public symbol = "OST";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10 ** uint256(decimals); // Initial supply
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;
    uint256 public exchangeRate;  // Exchange rate for 1 Orumyx Token to stable token
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ExchangeRateUpdated(uint256 newRate);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        balanceOf[msg.sender] = totalSupply;
        exchangeRate = 1000;  // Default exchange rate of 1 ORUMYX = 1000 OST (Stable Token)
    }

    // تابع برای انتقال توکن‌های استیبل
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "Transfer to the zero address is not allowed");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // تابع برای تایید انتقال توسط کاربر
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // تابع برای انتقال توکن‌های استیبل از طرف دیگر
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(sender != address(0), "Transfer from the zero address is not allowed");
        require(recipient != address(0), "Transfer to the zero address is not allowed");
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // تابع برای به‌روزرسانی نرخ تبدیل ORUMYX به توکن‌های استیبل
    function updateExchangeRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Exchange rate must be positive");
        exchangeRate = newRate;
        emit ExchangeRateUpdated(newRate);
    }

    // تابع برای مشاهده نرخ تبدیل ORUMYX به توکن‌های استیبل
    function getExchangeRate() external view returns (uint256) {
        return exchangeRate;
    }

    // تابع برای سوزاندن توکن‌ها
    function burn(uint256 amount) external onlyOwner {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance to burn");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxLiquidityPool {
    string public name = "Orumyx Liquidity Pool";
    address public owner;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidityProviders;
    mapping(address => uint256) public userRewards;
    
    event LiquidityAdded(address indexed user, uint256 amount);
    event LiquidityRemoved(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 rewardAmount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }

    // تابع برای اضافه کردن نقدینگی به استخر
    function addLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        liquidityProviders[msg.sender] += amount;
        totalLiquidity += amount;
        emit LiquidityAdded(msg.sender, amount);
    }

    // تابع برای برداشت نقدینگی از استخر
    function removeLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(liquidityProviders[msg.sender] >= amount, "Insufficient liquidity balance");
        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;
        emit LiquidityRemoved(msg.sender, amount);
    }

    // تابع برای تخصیص پاداش به کاربران
    function claimReward() external {
        uint256 userLiquidity = liquidityProviders[msg.sender];
        require(userLiquidity > 0, "No liquidity to claim rewards");
        
        uint256 rewardAmount = calculateReward(msg.sender);
        userRewards[msg.sender] += rewardAmount;
        
        emit RewardClaimed(msg.sender, rewardAmount);
    }

    // تابع برای محاسبه پاداش یک کاربر بر اساس نقدینگی ارائه‌شده
    function calculateReward(address user) public view returns (uint256) {
        uint256 userLiquidity = liquidityProviders[user];
        uint256 reward = (userLiquidity * 100) / totalLiquidity; // پاداش نسبی به نقدینگی
        return reward;
    }

    // تابع برای مشاهده موجودی نقدینگی یک کاربر
    function getLiquidity(address user) external view returns (uint256) {
        return liquidityProviders[user];
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxToken {
    string public name = "Orumyx Token";
    string public symbol = "ORMX";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10 ** uint256(decimals);  // Supply in 18 decimals
        balances[owner] = totalSupply;  // Initially assigning all tokens to the owner
    }

    // تابع برای انتقال توکن‌ها
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "Invalid recipient address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // تابع برای مجاز کردن خرج کردن توکن‌ها توسط یک طرف ثالث
    function approve(address spender, uint256 amount) external returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // تابع برای برداشت توکن‌ها توسط طرف ثالث
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowed[sender][msg.sender] >= amount, "Allowance exceeded");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowed[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // تابع برای مشاهده موجودی یک کاربر
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // تابع برای مشاهده موجودی مجاز برای یک طرف ثالث
    function allowance(address owner, address spender) external view returns (uint256) {
        return allowed[owner][spender];
    }

    // تابع برای ایجاد توکن‌ها
    function mint(address account, uint256 amount) external onlyOwner returns (bool) {
        require(account != address(0), "Invalid address");
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }

    // تابع برای سوزاندن توکن‌ها
    function burn(uint256 amount) external onlyOwner returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");
        totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiquidityPool {
    string public name = "Orumyx Liquidity Pool";
    address public owner;
    address public tokenAddress;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidityProviders;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PoolCreated(address indexed owner, address tokenAddress);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier validDeposit(uint256 amount) {
        require(amount > 0, "Deposit amount must be greater than zero");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        emit PoolCreated(owner, tokenAddress);
    }

    // تابع برای واریز توکن‌ها به استخر
    function deposit(uint256 amount) external validDeposit(amount) {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        liquidityProviders[msg.sender] += amount;
        totalLiquidity += amount;

        emit Deposit(msg.sender, amount);
    }

    // تابع برای برداشت توکن‌ها از استخر
    function withdraw(uint256 amount) external {
        require(liquidityProviders[msg.sender] >= amount, "Insufficient liquidity");
        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;

        IERC20(tokenAddress).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    // تابع برای مشاهده موجودی استخر
    function getLiquidityBalance() external view returns (uint256) {
        return totalLiquidity;
    }

    // تابع برای مشاهده موجودی یک فرد در استخر
    function getUserLiquidity(address user) external view returns (uint256) {
        return liquidityProviders[user];
    }

    // تابع برای تعیین آدرس توکن‌های استخر
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenDistribution {
    string public name = "Orumyx Token Distribution";
    address public owner;
    address public liquidityPoolAddress;
    address public treasuryAddress;
    uint256 public totalSupply;
    uint256 public liquidityRewardPercentage = 5; // درصد پاداش برای استخر نقدینگی

    mapping(address => uint256) public balances;
    mapping(address => bool) public isExcludedFromReward;

    event TokensDistributed(address indexed user, uint256 amount);
    event RewardDistributed(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(uint256 _totalSupply, address _liquidityPoolAddress, address _treasuryAddress) {
        owner = msg.sender;
        totalSupply = _totalSupply;
        liquidityPoolAddress = _liquidityPoolAddress;
        treasuryAddress = _treasuryAddress;
        balances[owner] = _totalSupply; // تخصیص تمام توکن‌ها به مالک برای شروع
    }

    // تابع برای توزیع توکن‌ها
    function distributeTokens(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] += amounts[i];
            emit TokensDistributed(recipients[i], amounts[i]);
        }
    }

    // تابع برای محاسبه و توزیع پاداش استخر نقدینگی
    function distributeLiquidityRewards() external onlyOwner {
        uint256 liquidityBalance = IERC20(liquidityPoolAddress).balanceOf(address(this));
        uint256 rewardAmount = (liquidityBalance * liquidityRewardPercentage) / 100;

        balances[liquidityPoolAddress] += rewardAmount;
        emit RewardDistributed(liquidityPoolAddress, rewardAmount);
    }

    // تابع برای برداشت توکن‌ها از حساب
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // تابع برای مشاهده موجودی حساب یک کاربر
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    // تابع برای مشاهده موجودی استخر نقدینگی
    function liquidityPoolBalance() external view returns (uint256) {
        return IERC20(liquidityPoolAddress).balanceOf(address(this));
    }

    // تابع برای مشاهده موجودی خزانه
    function treasuryBalance() external view returns (uint256) {
        return address(treasuryAddress).balance;
    }

    // تابع برای اختصاص درصد پاداش به استخر نقدینگی
    function setLiquidityRewardPercentage(uint256 _percentage) external onlyOwner {
        liquidityRewardPercentage = _percentage;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Governance {
    string public name = "Orumyx Governance";
    address public owner;
    uint256 public totalSupply;
    uint256 public votingPeriod = 3 days;
    uint256 public proposalCount = 0;

    mapping(address => uint256) public balances;
    mapping(address => bool) public isExcludedFromVoting;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes;

    struct Proposal {
        address proposer;
        uint256 startTime;
        uint256 endTime;
        string description;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool executed;
    }

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(address indexed voter, uint256 indexed proposalId, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyDuringVotingPeriod(uint256 proposalId) {
        require(block.timestamp >= proposals[proposalId].startTime, "Voting hasn't started yet");
        require(block.timestamp <= proposals[proposalId].endTime, "Voting period has ended");
        _;
    }

    constructor(uint256 _totalSupply) {
        owner = msg.sender;
        totalSupply = _totalSupply;
        balances[owner] = _totalSupply; // تخصیص توکن‌ها به مالک برای شروع
    }

    // تابع برای ایجاد یک پیشنهاد جدید
    function createProposal(string memory description) external returns (uint256) {
        require(balances[msg.sender] > 0, "Only token holders can create proposals");
        proposalCount++;
        uint256 proposalId = proposalCount;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            description: description,
            voteCountYes: 0,
            voteCountNo: 0,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    // تابع برای رأی دادن به یک پیشنهاد
    function vote(uint256 proposalId, bool voteYes) external onlyDuringVotingPeriod(proposalId) {
        require(balances[msg.sender] > 0, "Only token holders can vote");
        require(!votes[msg.sender][proposalId], "You have already voted");

        votes[msg.sender][proposalId] = true;

        if (voteYes) {
            proposals[proposalId].voteCountYes++;
        } else {
            proposals[proposalId].voteCountNo++;
        }

        emit Voted(msg.sender, proposalId, voteYes);
    }

    // تابع برای اجرای یک پیشنهاد بعد از اتمام زمان رأی‌گیری
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp > proposal.endTime, "Voting period hasn't ended yet");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCountYes > proposal.voteCountNo, "Proposal didn't pass");

        proposal.executed = true;

        // اجرای تغییرات مورد نظر در اینجا

        emit ProposalExecuted(proposalId);
    }

    // تابع برای مشاهده وضعیت یک پیشنهاد
    function getProposalStatus(uint256 proposalId) external view returns (string memory status) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.executed) {
            return "Executed";
        } else if (block.timestamp <= proposal.endTime) {
            return "Voting in progress";
        } else if (proposal.voteCountYes > proposal.voteCountNo) {
            return "Proposal passed";
        } else {
            return "Proposal rejected";
        }
    }

    // تابع برای مشاهده جزئیات یک پیشنهاد
    function getProposalDetails(uint256 proposalId) external view returns (address proposer, string memory description, uint256 voteCountYes, uint256 voteCountNo, bool executed) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.proposer, proposal.description, proposal.voteCountYes, proposal.voteCountNo, proposal.executed);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiquidityPool {
    address public owner;
    uint256 public totalLiquidity;
    uint256 public liquidityFee = 2; // درصد کارمزد برای هر تراکنش
    uint256 public withdrawalFee = 1; // درصد کارمزد برای برداشت از استخر
    uint256 public constant MAX_FEE = 10; // حداکثر درصد کارمزدها
    mapping(address => uint256) public liquidityProviders;
    mapping(address => bool) public isLiquidityProvider;

    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event LiquidityTransferred(address indexed from, address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyLiquidityProvider() {
        require(isLiquidityProvider[msg.sender], "Only liquidity providers can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalLiquidity = 0;
    }

    // تابع برای افزودن نقدینگی به استخر
    function addLiquidity(uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than 0");

        uint256 fee = (amount * liquidityFee) / 100;
        uint256 amountAfterFee = amount - fee;

        liquidityProviders[msg.sender] += amountAfterFee;
        totalLiquidity += amountAfterFee;

        if (!isLiquidityProvider[msg.sender]) {
            isLiquidityProvider[msg.sender] = true;
        }

        emit LiquidityAdded(msg.sender, amountAfterFee);
    }

    // تابع برای برداشت نقدینگی از استخر
    function removeLiquidity(uint256 amount) external onlyLiquidityProvider {
        require(amount > 0, "Amount must be greater than 0");
        require(liquidityProviders[msg.sender] >= amount, "Insufficient liquidity");

        uint256 fee = (amount * withdrawalFee) / 100;
        uint256 amountAfterFee = amount - fee;

        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;

        payable(msg.sender).transfer(amountAfterFee);

        emit LiquidityRemoved(msg.sender, amountAfterFee);
    }

    // تابع برای انتقال نقدینگی به سایر کاربران
    function transferLiquidity(address to, uint256 amount) external onlyLiquidityProvider {
        require(to != msg.sender, "Cannot transfer liquidity to yourself");
        require(liquidityProviders[msg.sender] >= amount, "Insufficient liquidity");

        liquidityProviders[msg.sender] -= amount;
        liquidityProviders[to] += amount;

        emit LiquidityTransferred(msg.sender, to, amount);
    }

    // تابع برای تنظیم کارمزد نقدینگی
    function setLiquidityFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE, "Fee cannot exceed the maximum limit");
        liquidityFee = newFee;
    }

    // تابع برای تنظیم کارمزد برداشت
    function setWithdrawalFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE, "Fee cannot exceed the maximum limit");
        withdrawalFee = newFee;
    }

    // تابع برای مشاهده نقدینگی تأمین شده توسط یک کاربر
    function getLiquidity(address provider) external view returns (uint256) {
        return liquidityProviders[provider];
    }

    // تابع برای مشاهده نقدینگی کل استخر
    function getTotalLiquidity() external view returns (uint256) {
        return totalLiquidity;
    }

    // تابع برای مشاهده کارمزد نقدینگی
    function getLiquidityFee() external view returns (uint256) {
        return liquidityFee;
    }

    // تابع برای مشاهده کارمزد برداشت
    function getWithdrawalFee() external view returns (uint256) {
        return withdrawalFee;
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    uint256 public totalVotes;
    uint256 public votingFee = 1 ether; // هزینه برای شرکت در هر رای‌گیری
    uint256 public constant MAX_VOTING_PERIOD = 30 days; // حداکثر مدت زمان برای هر رای‌گیری
    uint256 public currentVotingId;
    
    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingDeadline;
        bool isOpen;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => uint256) public userVotes;
    
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 votingDeadline);
    event Voted(address indexed voter, uint256 indexed proposalId, bool vote);
    event VotingFeePaid(address indexed voter, uint256 amount);
    event VotingFeeUpdated(uint256 newFee);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    modifier onlyDuringVoting(uint256 proposalId) {
        require(proposals[proposalId].isOpen, "Voting for this proposal is closed.");
        require(block.timestamp < proposals[proposalId].votingDeadline, "Voting period has expired.");
        _;
    }

    modifier onlyAfterVotingDeadline(uint256 proposalId) {
        require(block.timestamp >= proposals[proposalId].votingDeadline, "Voting period has not yet ended.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای ایجاد یک پیشنهاد جدید
    function createProposal(string memory description, uint256 votingPeriod) external onlyOwner {
        require(votingPeriod <= MAX_VOTING_PERIOD, "Voting period exceeds maximum limit.");

        currentVotingId++;
        uint256 proposalId = currentVotingId;
        uint256 votingDeadline = block.timestamp + votingPeriod;

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            votesFor: 0,
            votesAgainst: 0,
            votingDeadline: votingDeadline,
            isOpen: true
        });

        emit ProposalCreated(proposalId, description, votingDeadline);
    }

    // تابع برای پرداخت هزینه و شرکت در رای‌گیری
    function payVotingFee() external payable {
        require(msg.value == votingFee, "Incorrect fee amount.");

        userVotes[msg.sender] += msg.value;

        emit VotingFeePaid(msg.sender, msg.value);
    }

    // تابع برای رای دادن به یک پیشنهاد
    function vote(uint256 proposalId, bool voteFor) external payable onlyDuringVoting(proposalId) {
        require(msg.value == votingFee, "Incorrect fee amount.");
        require(!hasVoted[msg.sender][proposalId], "You have already voted for this proposal.");

        hasVoted[msg.sender][proposalId] = true;

        if (voteFor) {
            proposals[proposalId].votesFor++;
        } else {
            proposals[proposalId].votesAgainst++;
        }

        emit Voted(msg.sender, proposalId, voteFor);
    }

    // تابع برای بستن رای‌گیری
    function closeVoting(uint256 proposalId) external onlyAfterVotingDeadline(proposalId) onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.isOpen, "Voting is already closed.");

        proposal.isOpen = false;
    }

    // تابع برای دریافت نتیجه رای‌گیری
    function getVotingResult(uint256 proposalId) external view returns (string memory, uint256 votesFor, uint256 votesAgainst, bool passed) {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.votesFor > proposal.votesAgainst);
    }

    // تابع برای تنظیم هزینه رای‌گیری
    function setVotingFee(uint256 newFee) external onlyOwner {
        votingFee = newFee;

        emit VotingFeeUpdated(newFee);
    }

    // تابع برای مشاهده جزئیات یک پیشنهاد
    function getProposalDetails(uint256 proposalId) external view returns (string memory description, uint256 votesFor, uint256 votesAgainst, uint256 votingDeadline, bool isOpen) {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.votingDeadline, proposal.isOpen);
    }
}



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDEXRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

contract LiquidityPoolManager {
    address public owner;
    IDEXRouter public dexRouter;
    address public orumyxToken;
    address public stableCoin; // مثال: USDT
    uint256 public liquidityPoolSize;
    
    event LiquidityAdded(address indexed provider, uint256 amountOrumyx, uint256 amountStableCoin, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountOrumyx, uint256 amountStableCoin, uint256 liquidity);
    event LiquidityPoolSizeUpdated(uint256 newSize);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    constructor(address _dexRouter, address _orumyxToken, address _stableCoin) {
        owner = msg.sender;
        dexRouter = IDEXRouter(_dexRouter);
        orumyxToken = _orumyxToken;
        stableCoin = _stableCoin;
    }

    // تابع برای اضافه کردن نقدینگی به استخر
    function addLiquidity(uint256 amountOrumyx, uint256 amountStableCoin) external onlyOwner {
        // انتقال توکن‌های اورومیکس و استیبل‌کوین به قرارداد
        require(IERC20(orumyxToken).transferFrom(msg.sender, address(this), amountOrumyx), "Transfer of Orumyx failed.");
        require(IERC20(stableCoin).transferFrom(msg.sender, address(this), amountStableCoin), "Transfer of StableCoin failed.");

        // اجازه دادن به دکس روتر برای برداشت توکن‌ها از قرارداد
        require(IERC20(orumyxToken).approve(address(dexRouter), amountOrumyx), "Approval failed for Orumyx.");
        require(IERC20(stableCoin).approve(address(dexRouter), amountStableCoin), "Approval failed for StableCoin.");

        // افزودن نقدینگی به استخر
        (uint256 amountA, uint256 amountB, uint256 liquidity) = dexRouter.addLiquidity(
            orumyxToken,
            stableCoin,
            amountOrumyx,
            amountStableCoin,
            0,
            0,
            address(this),
            block.timestamp
        );

        liquidityPoolSize += liquidity;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    // تابع برای برداشت نقدینگی از استخر
    function removeLiquidity(uint256 liquidity) external onlyOwner {
        require(liquidity <= liquidityPoolSize, "Insufficient liquidity in pool.");

        // اجازه دادن به دکس روتر برای برداشت نقدینگی از استخر
        require(IERC20(address(dexRouter)).approve(address(dexRouter), liquidity), "Approval failed for liquidity.");

        // برداشت نقدینگی از استخر
        (uint256 amountA, uint256 amountB) = dexRouter.removeLiquidity(
            orumyxToken,
            stableCoin,
            liquidity,
            0,
            0,
            address(this),
            block.timestamp
        );

        liquidityPoolSize -= liquidity;

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }

    // تابع برای به‌روزرسانی اندازه استخر نقدینگی
    function updateLiquidityPoolSize(uint256 newSize) external onlyOwner {
        liquidityPoolSize = newSize;
        emit LiquidityPoolSizeUpdated(newSize);
    }

    // تابع برای مشاهده اندازه استخر نقدینگی
    function getLiquidityPoolSize() external view returns (uint256) {
        return liquidityPoolSize;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RewardDistribution {
    address public owner;
    address public orumyxToken;
    uint256 public rewardRate; // درصد سود به ازای هر دوره
    uint256 public lastDistributionTime;
    uint256 public totalDistributed;
    
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userLastClaimTime;
    
    event RewardDistributed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    constructor(address _orumyxToken, uint256 _initialRewardRate) {
        owner = msg.sender;
        orumyxToken = _orumyxToken;
        rewardRate = _initialRewardRate;
        lastDistributionTime = block.timestamp;
    }

    // تابع برای به‌روزرسانی نرخ سود
    function updateRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }

    // تابع برای توزیع پاداش به کاربران
    function distributeRewards() external {
        uint256 timeElapsed = block.timestamp - lastDistributionTime;
        require(timeElapsed >= 1 days, "Rewards can only be distributed once per day.");

        uint256 totalRewards = (totalDistributed * rewardRate) / 100;

        // توزیع پاداش‌ها به کاربران
        for (address user : userBalances) {
            uint256 reward = (userBalances[user] * totalRewards) / totalDistributed;
            require(IERC20(orumyxToken).transfer(user, reward), "Reward distribution failed.");
            userLastClaimTime[user] = block.timestamp;
            emit RewardDistributed(user, reward);
        }

        totalDistributed = 0;
        lastDistributionTime = block.timestamp;
    }

    // تابع برای ثبت یا به‌روزرسانی موجودی کاربران
    function updateUserBalance(address user, uint256 balance) external onlyOwner {
        userBalances[user] = balance;
    }

    // تابع برای مشاهده موجودی یک کاربر
    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }
    
    // تابع برای مشاهده زمان آخرین درخواست پاداش یک کاربر
    function getUserLastClaimTime(address user) external view returns (uint256) {
        return userLastClaimTime[user];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CashReserve {
    address public owner;
    uint256 public reserveBalance;
    uint256 public withdrawalLimit; // حداکثر مبلغ قابل برداشت در یک دوره زمانی
    uint256 public lastWithdrawalTime; // زمان آخرین برداشت
    uint256 public withdrawalCooldown; // دوره زمانی بین برداشت‌ها

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    modifier hasSufficientFunds(uint256 amount) {
        require(reserveBalance >= amount, "Not enough funds in reserve.");
        _;
    }

    modifier cooldownPeriodPassed() {
        require(block.timestamp >= lastWithdrawalTime + withdrawalCooldown, "Cooldown period has not passed.");
        _;
    }

    constructor(uint256 _initialReserve, uint256 _withdrawalLimit, uint256 _withdrawalCooldown) {
        owner = msg.sender;
        reserveBalance = _initialReserve;
        withdrawalLimit = _withdrawalLimit;
        withdrawalCooldown = _withdrawalCooldown;
        lastWithdrawalTime = block.timestamp;
    }

    // تابع برای واریز وجه به ذخایر نقدی
    function deposit(uint256 amount) external onlyOwner {
        reserveBalance += amount;
        emit Deposit(msg.sender, amount);
    }

    // تابع برای برداشت از ذخایر نقدی
    function withdraw(uint256 amount) external onlyOwner hasSufficientFunds(amount) cooldownPeriodPassed {
        require(amount <= withdrawalLimit, "Amount exceeds withdrawal limit.");
        
        reserveBalance -= amount;
        payable(msg.sender).transfer(amount);
        lastWithdrawalTime = block.timestamp;
        emit Withdrawal(msg.sender, amount);
    }

    // تابع برای مشاهده موجودی ذخایر نقدی
    function getReserveBalance() external view returns (uint256) {
        return reserveBalance;
    }

    // تابع برای تنظیم محدودیت برداشت
    function setWithdrawalLimit(uint256 newLimit) external onlyOwner {
        withdrawalLimit = newLimit;
    }

    // تابع برای تنظیم دوره زمانی بین برداشت‌ها
    function setCooldownPeriod(uint256 newCooldown) external onlyOwner {
        withdrawalCooldown = newCooldown;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingAndTransparency {
    address public owner;
    mapping(address => bool) public voters;
    uint256 public totalVotes;
    mapping(string => uint256) public voteCount;
    string[] public proposals;
    mapping(address => bool) public hasVoted;
    
    event Voted(address indexed voter, string proposal);
    event NewProposalAdded(string proposal);
    event ProposalExecuted(string proposal);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "You have already voted.");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalVotes = 0;
    }

    // تابع برای اضافه کردن پیشنهادات جدید
    function addProposal(string calldata proposal) external onlyOwner {
        proposals.push(proposal);
        voteCount[proposal] = 0;
        emit NewProposalAdded(proposal);
    }

    // تابع برای انجام رای‌گیری
    function vote(string calldata proposal) external hasNotVoted {
        require(isValidProposal(proposal), "Invalid proposal.");
        voteCount[proposal] += 1;
        hasVoted[msg.sender] = true;
        totalVotes += 1;
        emit Voted(msg.sender, proposal);
    }

    // تابع برای بررسی اینکه آیا پیشنهادی معتبر است یا خیر
    function isValidProposal(string calldata proposal) public view returns (bool) {
        for (uint i = 0; i < proposals.length; i++) {
            if (keccak256(abi.encodePacked(proposals[i])) == keccak256(abi.encodePacked(proposal))) {
                return true;
            }
        }
        return false;
    }

    // تابع برای اجرای پیشنهاد با بیشترین رای
    function executeProposal() external onlyOwner {
        require(totalVotes > 0, "No votes have been cast.");
        string memory winningProposal = getWinningProposal();
        emit ProposalExecuted(winningProposal);
        // به عنوان مثال، در اینجا می‌توان عملیات خاصی برای پیشنهاد برنده اضافه کرد
    }

    // تابع برای گرفتن پیشنهاد برنده
    function getWinningProposal() public view returns (string memory) {
        uint256 maxVotes = 0;
        string memory winningProposal = "";
        for (uint i = 0; i < proposals.length; i++) {
            if (voteCount[proposals[i]] > maxVotes) {
                maxVotes = voteCount[proposals[i]];
                winningProposal = proposals[i];
            }
        }
        return winningProposal;
    }

    // تابع برای مشاهده تعداد کل آرا
    function getTotalVotes() external view returns (uint256) {
        return totalVotes;
    }

    // تابع برای مشاهده رای هر پیشنهاد
    function getVoteCount(string calldata proposal) external view returns (uint256) {
        return voteCount[proposal];
    }

    // تابع برای مشاهده تمام پیشنهادات
    function getAllProposals() external view returns (string[] memory) {
        return proposals;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiquidityPool {
    address public owner;
    mapping(address => uint256) public liquidityProviders;
    uint256 public totalLiquidity;

    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event LiquidityPoolUpdated(uint256 newTotalLiquidity);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    modifier onlyLiquidityProvider() {
        require(liquidityProviders[msg.sender] > 0, "You must be a liquidity provider.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای اضافه کردن نقدینگی به استخر
    function addLiquidity() external payable {
        require(msg.value > 0, "You must send some ether to add liquidity.");

        liquidityProviders[msg.sender] += msg.value;
        totalLiquidity += msg.value;

        emit LiquidityAdded(msg.sender, msg.value);
        emit LiquidityPoolUpdated(totalLiquidity);
    }

    // تابع برای برداشت نقدینگی از استخر
    function removeLiquidity(uint256 amount) external onlyLiquidityProvider {
        require(amount <= liquidityProviders[msg.sender], "Insufficient liquidity.");

        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;

        payable(msg.sender).transfer(amount);

        emit LiquidityRemoved(msg.sender, amount);
        emit LiquidityPoolUpdated(totalLiquidity);
    }

    // تابع برای مشاهده مقدار نقدینگی یک کاربر
    function getLiquidity(address user) external view returns (uint256) {
        return liquidityProviders[user];
    }

    // تابع برای مشاهده کل نقدینگی استخر
    function getTotalLiquidity() external view returns (uint256) {
        return totalLiquidity;
    }

    // تابع برای انتقال مالکیت قرارداد
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiquidityPool {
    address public owner;
    mapping(address => uint256) public liquidityProviders;
    uint256 public totalLiquidity;
    uint256 public totalShares;
    
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای اضافه کردن نقدینگی به استخر
    function addLiquidity() external payable {
        require(msg.value > 0, "You must send some ether to add liquidity.");
        liquidityProviders[msg.sender] += msg.value;
        totalLiquidity += msg.value;
        
        uint256 share = (msg.value * totalShares) / totalLiquidity;
        totalShares += share;

        emit LiquidityAdded(msg.sender, msg.value);
    }

    // تابع برای برداشت نقدینگی از استخر
    function removeLiquidity(uint256 amount) external {
        require(amount > 0 && liquidityProviders[msg.sender] >= amount, "Insufficient liquidity.");
        
        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;
        
        uint256 share = (amount * totalShares) / totalLiquidity;
        totalShares -= share;

        payable(msg.sender).transfer(amount);

        emit LiquidityRemoved(msg.sender, amount);
    }

    // تابع برای مشاهده میزان نقدینگی یک کاربر در استخر
    function getLiquidity(address user) external view returns (uint256) {
        return liquidityProviders[user];
    }

    // تابع برای مشاهده کل نقدینگی استخر
    function getTotalLiquidity() external view returns (uint256) {
        return totalLiquidity;
    }

    // تابع برای مشاهده تعداد کل سهام استخر
    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }

    // تابع برای انتقال مالکیت استخر
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CompensationFund {
    address public owner;
    uint256 public totalCompensationFunds;
    mapping(address => uint256) public compensationRequests;

    event CompensationRequested(address indexed investor, uint256 amount);
    event CompensationGranted(address indexed investor, uint256 amount);
    event FundsDeposited(address indexed sender, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    modifier onlyInvestor() {
        require(compensationRequests[msg.sender] > 0, "You are not eligible for compensation.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای واریز وجوه به صندوق جبران خسارت
    function depositFunds() external payable onlyOwner {
        require(msg.value > 0, "You must send some ether to deposit into the compensation fund.");
        totalCompensationFunds += msg.value;

        emit FundsDeposited(msg.sender, msg.value);
    }

    // تابع برای درخواست جبران خسارت
    function requestCompensation(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        compensationRequests[msg.sender] += amount;

        emit CompensationRequested(msg.sender, amount);
    }

    // تابع برای پرداخت جبران خسارت به سرمایه‌گذاران
    function grantCompensation(address investor) external onlyOwner {
        uint256 requestedAmount = compensationRequests[investor];
        require(requestedAmount > 0, "No compensation requested.");
        require(totalCompensationFunds >= requestedAmount, "Insufficient funds in compensation fund.");

        compensationRequests[investor] = 0;
        totalCompensationFunds -= requestedAmount;

        payable(investor).transfer(requestedAmount);

        emit CompensationGranted(investor, requestedAmount);
    }

    // تابع برای مشاهده میزان وجه درخواست شده برای جبران خسارت
    function getRequestedCompensation(address investor) external view returns (uint256) {
        return compensationRequests[investor];
    }

    // تابع برای مشاهده موجودی صندوق جبران خسارت
    function getTotalCompensationFunds() external view returns (uint256) {
        return totalCompensationFunds;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiquidityPool {
    address public owner;
    mapping(address => uint256) public liquidityProviders;
    uint256 public totalLiquidity;
    uint256 public constant MIN_LIQUIDITY = 1 ether;

    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event LiquidityTransferred(address indexed from, address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    modifier validLiquidityAmount(uint256 amount) {
        require(amount >= MIN_LIQUIDITY, "Amount must be greater than or equal to the minimum liquidity.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای اضافه کردن نقدینگی به استخر
    function addLiquidity() external payable validLiquidityAmount(msg.value) {
        liquidityProviders[msg.sender] += msg.value;
        totalLiquidity += msg.value;

        emit LiquidityAdded(msg.sender, msg.value);
    }

    // تابع برای برداشتن نقدینگی از استخر
    function removeLiquidity(uint256 amount) external {
        require(liquidityProviders[msg.sender] >= amount, "Insufficient liquidity.");
        
        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;
        
        payable(msg.sender).transfer(amount);
        
        emit LiquidityRemoved(msg.sender, amount);
    }

    // تابع برای انتقال نقدینگی بین ارائه‌دهندگان
    function transferLiquidity(address to, uint256 amount) external {
        require(liquidityProviders[msg.sender] >= amount, "Insufficient liquidity.");
        
        liquidityProviders[msg.sender] -= amount;
        liquidityProviders[to] += amount;
        
        emit LiquidityTransferred(msg.sender, to, amount);
    }

    // تابع برای مشاهده موجودی نقدینگی یک ارائه‌دهنده
    function getLiquidityBalance(address provider) external view returns (uint256) {
        return liquidityProviders[provider];
    }

    // تابع برای مشاهده موجودی کل نقدینگی استخر
    function getTotalLiquidity() external view returns (uint256) {
        return totalLiquidity;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReserveManagement {
    address public owner;
    uint256 public reserveBalance;
    mapping(address => uint256) public reserves;
    uint256 public investmentThreshold; // حد آستانه سرمایه‌گذاری
    address[] public investors;
    uint256 public totalInvested;

    event ReserveAdded(address indexed investor, uint256 amount);
    event ReserveWithdrawn(address indexed investor, uint256 amount);
    event InvestmentMade(address indexed investor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    modifier reserveThresholdMet(uint256 amount) {
        require(reserveBalance + amount >= investmentThreshold, "Investment threshold not met.");
        _;
    }

    constructor(uint256 _investmentThreshold) {
        owner = msg.sender;
        investmentThreshold = _investmentThreshold;
        reserveBalance = 0;
        totalInvested = 0;
    }

    // تابع برای اضافه کردن ذخایر به سیستم
    function addReserve() external payable {
        require(msg.value > 0, "Amount must be greater than zero.");
        reserves[msg.sender] += msg.value;
        reserveBalance += msg.value;
        investors.push(msg.sender);

        emit ReserveAdded(msg.sender, msg.value);
    }

    // تابع برای برداشت ذخایر توسط سرمایه‌گذاران
    function withdrawReserve(uint256 amount) external {
        require(reserves[msg.sender] >= amount, "Insufficient balance.");
        reserves[msg.sender] -= amount;
        reserveBalance -= amount;
        payable(msg.sender).transfer(amount);

        emit ReserveWithdrawn(msg.sender, amount);
    }

    // تابع برای انجام سرمایه‌گذاری زمانی که ذخایر به حد نصاب رسید
    function makeInvestment() external onlyOwner reserveThresholdMet(totalInvested) {
        // انجام سرمایه‌گذاری در پروژه‌ها یا دارایی‌های خاص
        totalInvested = reserveBalance;

        // برای مثال، فرض کنید در اینجا سرمایه‌گذاری انجام می‌شود
        // ممکن است قراردادهای هوشمند دیگر برای سرمایه‌گذاری در دارایی‌های خاص، مانند طلا یا نفت، نیاز باشد.

        emit InvestmentMade(owner, reserveBalance);
    }

    // تابع برای مشاهده موجودی ذخایر
    function getReserveBalance() external view returns (uint256) {
        return reserveBalance;
    }

    // تابع برای مشاهده موجودی ذخایر یک کاربر خاص
    function getUserReserveBalance(address user) external view returns (uint256) {
        return reserves[user];
    }

    // تابع برای تنظیم حد آستانه سرمایه‌گذاری
    function setInvestmentThreshold(uint256 newThreshold) external onlyOwner {
        investmentThreshold = newThreshold;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecurityAndTransparency {
    address public owner;
    mapping(address => uint256) public userBalances;
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public lastWithdrawTime;
    
    uint256 public maxWithdrawLimit;
    uint256 public minWithdrawTime;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Blacklisted(address indexed user);
    event Unblacklisted(address indexed user);
    event FundsTransferred(address indexed from, address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    modifier notBlacklisted() {
        require(!isBlacklisted[msg.sender], "You are blacklisted and cannot perform this action.");
        _;
    }

    modifier canWithdraw(uint256 amount) {
        require(userBalances[msg.sender] >= amount, "Insufficient balance.");
        require(block.timestamp >= lastWithdrawTime[msg.sender] + minWithdrawTime, "Cannot withdraw yet.");
        require(amount <= maxWithdrawLimit, "Withdrawal exceeds maximum limit.");
        _;
    }

    constructor(uint256 _maxWithdrawLimit, uint256 _minWithdrawTime) {
        owner = msg.sender;
        maxWithdrawLimit = _maxWithdrawLimit;
        minWithdrawTime = _minWithdrawTime;
    }

    // تابع برای واریز پول به حساب
    function deposit() external payable {
        require(msg.value > 0, "Amount must be greater than zero.");
        userBalances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    // تابع برای برداشت پول از حساب
    function withdraw(uint256 amount) external notBlacklisted canWithdraw(amount) {
        userBalances[msg.sender] -= amount;
        lastWithdrawTime[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount);
    }

    // تابع برای انتقال وجوه
    function transferFunds(address recipient, uint256 amount) external notBlacklisted canWithdraw(amount) {
        require(recipient != address(0), "Invalid recipient address.");
        userBalances[msg.sender] -= amount;
        userBalances[recipient] += amount;

        emit FundsTransferred(msg.sender, recipient, amount);
    }

    // تابع برای اضافه کردن یک کاربر به لیست سیاه
    function blacklistUser(address user) external onlyOwner {
        isBlacklisted[user] = true;
        emit Blacklisted(user);
    }

    // تابع برای حذف یک کاربر از لیست سیاه
    function unblacklistUser(address user) external onlyOwner {
        isBlacklisted[user] = false;
        emit Unblacklisted(user);
    }

    // تابع برای مشاهده موجودی یک کاربر
    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }

    // تابع برای مشاهده لیست سیاه
    function isUserBlacklisted(address user) external view returns (bool) {
        return isBlacklisted[user];
    }

    // تابع برای تنظیم حد برداشت حداکثر
    function setMaxWithdrawLimit(uint256 newLimit) external onlyOwner {
        maxWithdrawLimit = newLimit;
    }

    // تابع برای تنظیم حد زمان بین برداشت‌ها
    function setMinWithdrawTime(uint256 newTime) external onlyOwner {
        minWithdrawTime = newTime;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReserveUsage {
    address public owner;
    uint256 public totalReserve;
    mapping(address => uint256) public userReserve;

    event ReserveUsed(address indexed user, uint256 amount, string reason);
    event FundsTransferred(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalReserve = 0;
    }

    // تابع برای استفاده از ذخایر برای بهبود و توسعه ارز
    function useReserve(address user, uint256 amount, string calldata reason) external onlyOwner {
        require(userReserve[user] >= amount, "Insufficient reserve to use.");
        userReserve[user] -= amount;
        totalReserve -= amount;
        emit ReserveUsed(user, amount, reason);
    }

    // تابع برای انتقال ذخایر برای بهبود پروژه
    function transferFunds(address payable to, uint256 amount) external onlyOwner {
        require(totalReserve >= amount, "Insufficient total reserve.");
        totalReserve -= amount;
        to.transfer(amount);
        emit FundsTransferred(to, amount);
    }

    // تابع برای دریافت کل ذخایر سیستم
    function getTotalReserve() external view returns (uint256) {
        return totalReserve;
    }

    // تابع برای مشاهده ذخایر یک کاربر
    function getUserReserve(address user) external view returns (uint256) {
        return userReserve[user];
    }

    // تابع برای افزودن ذخایر به سیستم
    function addReserve(address user, uint256 amount) external onlyOwner {
        userReserve[user] += amount;
        totalReserve += amount;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedVoting {
    address public owner;
    mapping(address => uint256) public votingPower;
    mapping(bytes32 => uint256) public votesFor;
    mapping(bytes32 => uint256) public votesAgainst;
    mapping(address => mapping(bytes32 => bool)) public hasVoted;

    event Voted(address indexed voter, bytes32 proposal, bool vote);
    event ProposalCreated(bytes32 indexed proposal, string description);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this function.");
        _;
    }

    modifier hasNotVoted(bytes32 proposal) {
        require(!hasVoted[msg.sender][proposal], "You have already voted on this proposal.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // تابع برای ایجاد یک پیشنهاد جدید
    function createProposal(bytes32 proposalId, string calldata description) external onlyOwner {
        emit ProposalCreated(proposalId, description);
    }

    // تابع برای رأی دادن به یک پیشنهاد
    function vote(bytes32 proposalId, bool voteChoice) external hasNotVoted(proposalId) {
        uint256 power = votingPower[msg.sender];
        require(power > 0, "You must have voting power to vote.");
        
        if (voteChoice) {
            votesFor[proposalId] += power;
        } else {
            votesAgainst[proposalId] += power;
        }

        hasVoted[msg.sender][proposalId] = true;
        emit Voted(msg.sender, proposalId, voteChoice);
    }

    // تابع برای اضافه کردن حق رای به کاربران
    function addVotingPower(address user, uint256 power) external onlyOwner {
        votingPower[user] += power;
    }

    // تابع برای مشاهده تعداد آراء برای یک پیشنهاد
    function getVotesFor(bytes32 proposalId) external view returns (uint256) {
        return votesFor[proposalId];
    }

    // تابع برای مشاهده تعداد آراء مخالف یک پیشنهاد
    function getVotesAgainst(bytes32 proposalId) external view returns (uint256) {
        return votesAgainst[proposalId];
    }

    // تابع برای مشاهده حق رای یک کاربر
    function getVotingPower(address user) external view returns (uint256) {
        return votingPower[user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

contract LiquidityPool {
    address public owner;
    address public orumyxToken;
    IUniswapV2Router public uniswapRouter;

    event LiquidityAdded(address indexed user, uint256 amountOrumyx, uint256 amountUSD, uint256 liquidity);
    event LiquidityRemoved(address indexed user, uint256 amountOrumyx, uint256 amountUSD, uint256 liquidity);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    constructor(address _orumyxToken, address _uniswapRouter) {
        owner = msg.sender;
        orumyxToken = _orumyxToken;
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
    }

    // تابع برای افزودن نقدینگی به استخر
    function addLiquidity(uint256 amountOrumyx, uint256 amountUSD) external {
        // اجازه می‌دهیم که قرارداد برای اضافه کردن نقدینگی، توکن‌ها را از کاربران دریافت کند
        require(IERC20(orumyxToken).transferFrom(msg.sender, address(this), amountOrumyx), "Transfer failed.");
        
        // تخصیص حداقل مقدارهای مورد نیاز برای افزودن نقدینگی به استخر
        uint256 amountAMin = amountOrumyx * 995 / 1000; // 0.5% slippage
        uint256 amountBMin = amountUSD * 995 / 1000; // 0.5% slippage

        // اضافه کردن نقدینگی به صرافی غیرمتمرکز (مانند Uniswap)
        (uint256 amountOrumyxUsed, uint256 amountUSDUsed, uint256 liquidity) = uniswapRouter.addLiquidity(
            orumyxToken,
            address(0), // به عنوان مثال فرضی برای توکن USD
            amountOrumyx,
            amountUSD,
            amountAMin,
            amountBMin,
            msg.sender,
            block.timestamp
        );

        emit LiquidityAdded(msg.sender, amountOrumyxUsed, amountUSDUsed, liquidity);
    }

    // تابع برای برداشتن نقدینگی از استخر
    function removeLiquidity(uint256 liquidity) external {
        // برای برداشتن نقدینگی از استخر، ابتدا باید قرارداد اجازه برداشت از صرافی غیرمتمرکز را دریافت کند
        uint256 amountAMin = 0;
        uint256 amountBMin = 0;

        (uint256 amountOrumyx, uint256 amountUSD) = uniswapRouter.removeLiquidity(
            orumyxToken,
            address(0), // همانند افزودن نقدینگی، توکن USD
            liquidity,
            amountAMin,
            amountBMin,
            msg.sender,
            block.timestamp
        );

        emit LiquidityRemoved(msg.sender, amountOrumyx, amountUSD, liquidity);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DAO {
    address public owner;
    uint256 public proposalCount;
    
    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        uint256 endTime;
        bool executed;
    }

    mapping(address => bool) public hasVoted;
    mapping(uint256 => Proposal) public proposals;
    
    event ProposalCreated(uint256 proposalId, string description, uint256 endTime);
    event Voted(uint256 proposalId, bool voteFor, address voter);
    event ProposalExecuted(uint256 proposalId, bool success);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposals[proposalId].id == proposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalNotExecuted(uint256 proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier onlyActiveProposal(uint256 proposalId) {
        require(block.timestamp < proposals[proposalId].endTime, "Voting has ended.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createProposal(string memory _description, uint256 _duration) external onlyOwner {
        proposalCount++;
        uint256 endTime = block.timestamp + _duration;

        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: _description,
            voteCountFor: 0,
            voteCountAgainst: 0,
            endTime: endTime,
            executed: false
        });

        emit ProposalCreated(proposalCount, _description, endTime);
    }

    function vote(uint256 proposalId, bool voteFor) external proposalExists(proposalId) onlyActiveProposal(proposalId) {
        require(!hasVoted[msg.sender], "You have already voted.");
        
        hasVoted[msg.sender] = true;
        
        if (voteFor) {
            proposals[proposalId].voteCountFor++;
        } else {
            proposals[proposalId].voteCountAgainst++;
        }
        
        emit Voted(proposalId, voteFor, msg.sender);
    }

    function executeProposal(uint256 proposalId) external proposalExists(proposalId) proposalNotExecuted(proposalId) {
        require(block.timestamp >= proposals[proposalId].endTime, "Voting has not ended.");
        
        Proposal storage proposal = proposals[proposalId];
        
        bool success = proposal.voteCountFor > proposal.voteCountAgainst;
        proposal.executed = true;
        
        if (success) {
            // Execute proposal logic (e.g., deploy funds, change settings)
        }

        emit ProposalExecuted(proposalId, success);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FundManagement {
    address public owner;
    uint256 public totalFunds;
    
    mapping(address => uint256) public fundBalances;
    
    event FundDeposited(address indexed user, uint256 amount);
    event FundWithdrawn(address indexed user, uint256 amount);
    event FundAllocated(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    modifier hasSufficientFunds(address user, uint256 amount) {
        require(fundBalances[user] >= amount, "Insufficient funds.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function depositFunds() external payable {
        fundBalances[msg.sender] += msg.value;
        totalFunds += msg.value;
        
        emit FundDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(uint256 amount) external hasSufficientFunds(msg.sender, amount) {
        fundBalances[msg.sender] -= amount;
        totalFunds -= amount;
        payable(msg.sender).transfer(amount);
        
        emit FundWithdrawn(msg.sender, amount);
    }

    function allocateFunds(address recipient, uint256 amount) external onlyOwner hasSufficientFunds(address(this), amount) {
        fundBalances[address(this)] -= amount;
        fundBalances[recipient] += amount;
        
        emit FundAllocated(recipient, amount);
    }

    function checkBalance() external view returns (uint256) {
        return fundBalances[msg.sender];
    }

    function getTotalFunds() external view returns (uint256) {
        return totalFunds;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    uint256 public totalVotes;
    
    struct Proposal {
        string description;
        uint256 voteCount;
        bool isActive;
        uint256 deadline;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public voterBalances;

    event ProposalCreated(uint256 indexed proposalId, string description);
    event Voted(address indexed voter, uint256 indexed proposalId);
    event ProposalClosed(uint256 indexed proposalId, bool approved);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    modifier onlyActiveProposal(uint256 proposalId) {
        require(proposals[proposalId].isActive, "Proposal is not active.");
        _;
    }

    modifier proposalDeadlinePassed(uint256 proposalId) {
        require(block.timestamp > proposals[proposalId].deadline, "Deadline not passed yet.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createProposal(string memory description, uint256 duration) external onlyOwner {
        uint256 proposalId = totalVotes;
        proposals[proposalId] = Proposal({
            description: description,
            voteCount: 0,
            isActive: true,
            deadline: block.timestamp + duration
        });
        
        totalVotes++;
        
        emit ProposalCreated(proposalId, description);
    }

    function vote(uint256 proposalId) external onlyActiveProposal(proposalId) {
        require(voterBalances[msg.sender] > 0, "No voting rights.");
        
        proposals[proposalId].voteCount += voterBalances[msg.sender];
        voterBalances[msg.sender] = 0;  // After voting, voter loses voting power
        
        emit Voted(msg.sender, proposalId);
    }

    function closeProposal(uint256 proposalId) external onlyOwner proposalDeadlinePassed(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        proposal.isActive = false;
        
        bool approved = proposal.voteCount > totalVotes / 2; // Majority wins
        emit ProposalClosed(proposalId, approved);
    }

    function allocateVotingRights(address voter, uint256 amount) external onlyOwner {
        voterBalances[voter] += amount;
    }

    function getProposalDetails(uint256 proposalId) external view returns (string memory description, uint256 voteCount, bool isActive, uint256 deadline) {
        Proposal memory proposal = proposals[proposalId];
        return (proposal.description, proposal.voteCount, proposal.isActive, proposal.deadline);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiquidityPool {
    address public owner;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidityProviders;
    mapping(address => uint256) public balances;

    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Function to add liquidity to the pool
    function addLiquidity() external payable {
        require(msg.value > 0, "Must send some value to add liquidity.");
        liquidityProviders[msg.sender] += msg.value;
        totalLiquidity += msg.value;
        
        emit LiquidityAdded(msg.sender, msg.value);
    }

    // Function to remove liquidity from the pool
    function removeLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        require(liquidityProviders[msg.sender] >= amount, "Not enough liquidity to remove.");

        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;
        payable(msg.sender).transfer(amount);

        emit LiquidityRemoved(msg.sender, amount);
    }

    // Function to check the current balance of the liquidity provider
    function checkBalance() external view returns (uint256) {
        return liquidityProviders[msg.sender];
    }

    // Function to distribute rewards (for example, in future versions, rewards could be based on fees)
    function distributeRewards() external onlyOwner {
        // Example reward distribution logic
        // Rewards could be distributed based on the liquidity contributed by each provider
        for (address provider : liquidityProviders) {
            // Here, you can implement the logic to distribute rewards
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RewardAndCashReserve {
    address public owner;
    uint256 public cashReserve;
    uint256 public rewardPool;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public contributions;

    event RewardsDistributed(address indexed provider, uint256 reward);
    event CashReserveUpdated(uint256 newReserveAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        cashReserve = 0;
        rewardPool = 0;
    }

    // Function to update the cash reserve for immediate withdrawals
    function updateCashReserve(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0.");
        cashReserve += amount;
        emit CashReserveUpdated(cashReserve);
    }

    // Function to withdraw from the cash reserve
    function withdrawFromReserve(uint256 amount) external onlyOwner {
        require(amount <= cashReserve, "Insufficient cash reserve.");
        cashReserve -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Function to add contributions to the reward pool
    function addToRewardPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0.");
        rewardPool += amount;
    }

    // Function to distribute rewards based on user contributions
    function distributeRewards() external onlyOwner {
        require(rewardPool > 0, "No rewards available to distribute.");
        
        uint256 totalContributions = getTotalContributions();
        require(totalContributions > 0, "No contributions found.");

        // Distribute rewards proportionally to each contributor
        for (address contributor : contributors) {
            uint256 reward = (contributions[contributor] * rewardPool) / totalContributions;
            rewards[contributor] += reward;
            emit RewardsDistributed(contributor, reward);
        }

        // Reset the reward pool after distribution
        rewardPool = 0;
    }

    // Helper function to get the total contributions in the system
    function getTotalContributions() public view returns (uint256 total) {
        total = 0;
        for (address contributor : contributors) {
            total += contributions[contributor];
        }
    }

    // Function to allow users to claim their rewards
    function claimRewards() external {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards available to claim.");
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(reward);
    }

    // Function to record user contributions to the liquidity pool
    function recordContribution(address contributor, uint256 amount) external onlyOwner {
        contributions[contributor] += amount;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingMechanism {
    address public owner;
    uint256 public totalVotes;
    mapping(address => uint256) public votes;
    mapping(address => bool) public hasVoted;
    mapping(address => bool) public validators;

    event VoteCast(address indexed voter, uint256 votes);
    event ValidationPassed(address indexed validator, bool result);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    modifier onlyValidator() {
        require(validators[msg.sender], "Only a validator can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalVotes = 0;
    }

    // Function to add a new validator
    function addValidator(address validator) external onlyOwner {
        validators[validator] = true;
    }

    // Function to remove a validator
    function removeValidator(address validator) external onlyOwner {
        validators[validator] = false;
    }

    // Function to allow a user to vote
    function vote(uint256 amount) external {
        require(!hasVoted[msg.sender], "You have already voted.");
        require(amount > 0, "Vote amount must be greater than 0.");
        votes[msg.sender] = amount;
        totalVotes += amount;
        hasVoted[msg.sender] = true;
        emit VoteCast(msg.sender, amount);
    }

    // Function to start the validation process
    function validate(uint256 requiredVotes) external onlyValidator {
        require(totalVotes >= requiredVotes, "Not enough votes to validate.");

        bool isValid = checkValidity(); // Replace with logic for validity check

        // Emit the result of the validation process
        emit ValidationPassed(msg.sender, isValid);
    }

    // Helper function to check validity (custom logic can be added here)
    function checkValidity() internal pure returns (bool) {
        // Custom logic to validate data or assets
        return true; // Placeholder for actual validation logic
    }

    // Function to withdraw all votes in case of dispute or other conditions
    function withdrawVotes() external {
        require(hasVoted[msg.sender], "You have not voted.");
        totalVotes -= votes[msg.sender];
        votes[msg.sender] = 0;
        hasVoted[msg.sender] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InvestmentPool {
    address public owner;
    uint256 public totalFunds;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public approvedExpenditures;

    event FundsDeposited(address indexed contributor, uint256 amount);
    event FundsWithdrawn(address indexed withdrawer, uint256 amount);
    event ExpenditureApproved(address indexed approver, uint256 amount, string purpose);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    modifier onlyApproved() {
        require(approvedExpenditures[msg.sender], "Only approved individuals can spend funds.");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalFunds = 0;
    }

    // Function to allow users to contribute to the investment pool
    function contribute() external payable {
        require(msg.value > 0, "Contribution must be greater than 0.");
        contributions[msg.sender] += msg.value;
        totalFunds += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    // Function to approve an expenditure
    function approveExpenditure(address spender, uint256 amount, string memory purpose) external onlyOwner {
        require(amount <= totalFunds, "Insufficient funds in the pool.");
        approvedExpenditures[spender] = true;
        emit ExpenditureApproved(spender, amount, purpose);
    }

    // Function to spend funds once approved
    function spendFunds(uint256 amount) external onlyApproved {
        require(amount <= totalFunds, "Insufficient funds in the pool.");
        totalFunds -= amount;
        payable(msg.sender).transfer(amount);
        emit FundsWithdrawn(msg.sender, amount);
    }

    // Function to check the current balance of the pool
    function getPoolBalance() external view returns (uint256) {
        return totalFunds;
    }

    // Function to withdraw a user's contribution (if applicable)
    function withdrawContribution(uint256 amount) external {
        require(contributions[msg.sender] >= amount, "Insufficient contribution balance.");
        contributions[msg.sender] -= amount;
        totalFunds -= amount;
        payable(msg.sender).transfer(amount);
        emit FundsWithdrawn(msg.sender, amount);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract LiquidityPoolSupport {
    address public owner;
    address public liquidityPoolAddress;
    IToken public token;
    
    event LiquidityAdded(address indexed user, uint256 amount);
    event LiquidityRemoved(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }
    
    constructor(address _tokenAddress, address _liquidityPoolAddress) {
        owner = msg.sender;
        token = IToken(_tokenAddress);
        liquidityPoolAddress = _liquidityPoolAddress;
    }
    
    // Function to add liquidity to the liquidity pool
    function addLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        
        // Transfer the token to the liquidity pool
        require(token.transferFrom(msg.sender, liquidityPoolAddress, amount), "Transfer failed.");
        
        emit LiquidityAdded(msg.sender, amount);
    }
    
    // Function to remove liquidity from the liquidity pool
    function removeLiquidity(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        
        uint256 balanceInPool = token.balanceOf(liquidityPoolAddress);
        require(balanceInPool >= amount, "Not enough liquidity in the pool.");
        
        // Transfer the token from the liquidity pool to the user
        require(token.transferFrom(liquidityPoolAddress, msg.sender, amount), "Transfer failed.");
        
        emit LiquidityRemoved(msg.sender, amount);
    }
    
    // Function to check the user's liquidity balance in the pool
    function getUserLiquidityBalance() external view returns (uint256) {
        return token.balanceOf(msg.sender);
    }
    
    // Function to check the liquidity pool balance
    function getLiquidityPoolBalance() external view returns (uint256) {
        return token.balanceOf(liquidityPoolAddress);
    }
    
    // Owner can update liquidity pool address if necessary
    function updateLiquidityPoolAddress(address _newLiquidityPoolAddress) external onlyOwner {
        liquidityPoolAddress = _newLiquidityPoolAddress;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WalletManagement {
    address public owner;
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Deposit function to add funds to the contract
    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than 0.");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // Withdraw function to remove funds from the contract
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than 0.");
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        
        // Transfer funds to the user
        payable(msg.sender).transfer(amount);
        balances[msg.sender] -= amount;
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // Function to check the contract's balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // Owner can withdraw funds from the contract
    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "Withdrawal amount must be greater than 0.");
        require(address(this).balance >= amount, "Insufficient contract balance.");
        
        payable(owner).transfer(amount);
    }
    
    // Function to check the user's balance
    function getUserBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LiquidityPool {
    address public owner;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidityProviders;
    
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Add liquidity to the pool
    function addLiquidity() external payable {
        require(msg.value > 0, "Liquidity must be greater than 0.");
        
        // Update total liquidity and user's contribution
        totalLiquidity += msg.value;
        liquidityProviders[msg.sender] += msg.value;
        
        emit LiquidityAdded(msg.sender, msg.value);
    }
    
    // Remove liquidity from the pool
    function removeLiquidity(uint256 amount) external {
        require(amount > 0, "Removal amount must be greater than 0.");
        require(liquidityProviders[msg.sender] >= amount, "Insufficient liquidity.");
        
        // Update total liquidity and user's contribution
        totalLiquidity -= amount;
        liquidityProviders[msg.sender] -= amount;
        
        // Transfer liquidity to the user
        payable(msg.sender).transfer(amount);
        
        emit LiquidityRemoved(msg.sender, amount);
    }
    
    // Get total liquidity in the pool
    function getTotalLiquidity() external view returns (uint256) {
        return totalLiquidity;
    }
    
    // Get user's liquidity balance
    function getUserLiquidity() external view returns (uint256) {
        return liquidityProviders[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OrumyxToken is IERC20 {
    string public constant name = "Orumyx";
    string public constant symbol = "ORMX";
    uint8 public constant decimals = 18;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    constructor(uint256 initialSupply) {
        _totalSupply = initialSupply * (10 ** uint256(decimals));
        _balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Transfer to the zero address is not allowed.");
        require(_balances[msg.sender] >= amount, "Insufficient balance.");
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Approve to the zero address is not allowed.");
        
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0), "Transfer from the zero address is not allowed.");
        require(recipient != address(0), "Transfer to the zero address is not allowed.");
        require(_balances[sender] >= amount, "Insufficient balance.");
        require(_allowances[sender][msg.sender] >= amount, "Allowance exceeded.");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Governance {
    address public owner;
    mapping(address => bool) public voters;
    mapping(address => uint256) public votes;
    uint256 public totalVotes;
    uint256 public quorum;

    event ProposalCreated(uint256 proposalId, string description);
    event Voted(address indexed voter, uint256 proposalId, bool vote);
    
    struct Proposal {
        string description;
        uint256 voteCount;
        bool executed;
    }

    Proposal[] public proposals;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyVoter() {
        require(voters[msg.sender], "You are not eligible to vote");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposals.length, "Proposal does not exist");
        _;
    }

    constructor(uint256 _quorum) {
        owner = msg.sender;
        quorum = _quorum; // Set quorum as a percentage of total supply
    }

    function addVoter(address voter) public onlyOwner {
        voters[voter] = true;
    }

    function removeVoter(address voter) public onlyOwner {
        voters[voter] = false;
    }

    function createProposal(string memory description) public onlyOwner {
        proposals.push(Proposal({
            description: description,
            voteCount: 0,
            executed: false
        }));

        emit ProposalCreated(proposals.length - 1, description);
    }

    function vote(uint256 proposalId, bool _vote) public onlyVoter proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        require(!proposal.executed, "Proposal already executed");
        
        if (_vote) {
            proposal.voteCount++;
        } else {
            proposal.voteCount--;
        }

        emit Voted(msg.sender, proposalId, _vote);
    }

    function executeProposal(uint256 proposalId) public onlyOwner proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];

        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount >= quorum, "Quorum not reached");

        // Execute proposal logic here (for example, change state or trigger actions)

        proposal.executed = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SpecialContracts {
    address public owner;
    mapping(address => bool) public authorizedContracts;
    
    event ContractAuthorized(address contractAddress);
    event ContractRevoked(address contractAddress);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedContracts[msg.sender], "This contract is not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Authorize a new contract to interact with the system
    function authorizeContract(address contractAddress) public onlyOwner {
        authorizedContracts[contractAddress] = true;
        emit ContractAuthorized(contractAddress);
    }

    // Revoke authorization of a contract
    function revokeContract(address contractAddress) public onlyOwner {
        authorizedContracts[contractAddress] = false;
        emit ContractRevoked(contractAddress);
    }

    // Example function that can only be called by an authorized contract
    function specialFunction() public onlyAuthorized returns (string memory) {
        return "This function can only be called by an authorized contract.";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FeeManagement {
    address public owner;
    uint256 public feePercentage;
    uint256 public totalFeesCollected;
    mapping(address => uint256) public userFees;

    event FeeUpdated(uint256 newFeePercentage);
    event FeeCollected(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(uint256 initialFeePercentage) {
        owner = msg.sender;
        feePercentage = initialFeePercentage;
    }

    // Set a new fee percentage for the system
    function setFeePercentage(uint256 newFeePercentage) public onlyOwner {
        feePercentage = newFeePercentage;
        emit FeeUpdated(newFeePercentage);
    }

    // Function to collect fees when users perform transactions or actions
    function collectFee(address user, uint256 amount) public onlyOwner {
        uint256 feeAmount = (amount * feePercentage) / 100;
        totalFeesCollected += feeAmount;
        userFees[user] += feeAmount;

        emit FeeCollected(user, feeAmount);
    }

    // Withdraw collected fees to a specific address (e.g., the project wallet)
    function withdrawFees(address payable to, uint256 amount) public onlyOwner {
        require(amount <= totalFeesCollected, "Insufficient fee balance");
        totalFeesCollected -= amount;
        to.transfer(amount);
    }

    // Fallback function to accept Ether
    receive() external payable {}
}









