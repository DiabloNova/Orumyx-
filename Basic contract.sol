// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// وارد کردن کتابخانه SafeMath برای انجام عملیات ریاضی به صورت امن
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

// شروع قرارداد
contract Orumyx {
    using SafeMath for uint256;

    // اطلاعات مالک و موجودی‌ها
    address public owner;
    string public name = "Orumyx Token";
    string public symbol = "ORUMYX";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    // نقشه نگهداری موجودی‌ها و مجوزها
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // رویدادهای قرارداد
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // سازنده قرارداد (مقدار اولیه عرضه را تعیین می‌کند)
    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10**uint256(decimals);
        balances[owner] = totalSupply;
    }

    // انتقال توکن از یک آدرس به آدرس دیگر
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Orumyx: transfer to the zero address");
        require(balances[msg.sender] >= amount, "Orumyx: insufficient balance");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // تایید اجازه برداشت از طرف مالک توکن
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Orumyx: approve to the zero address");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // انتقال توکن از یک آدرس به آدرس دیگر توسط یک آدرس تایید شده
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0), "Orumyx: transfer from the zero address");
        require(recipient != address(0), "Orumyx: transfer to the zero address");
        require(balances[sender] >= amount, "Orumyx: insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Orumyx: transfer amount exceeds allowance");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        allowance[sender][msg.sender] = allowance[sender][msg.sender].sub(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // بررسی موجودی یک آدرس
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    // تایید میزان برداشت مجاز از سوی صاحب توکن
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }
}
// Part 2: Tokenomics and Token Distribution

contract OrumyxToken {
    string public name = "Orumyx Token";
    string public symbol = "OMX";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    uint256 public reservePercentage = 10; // Percentage for reserve pool
    uint256 public liquidityPoolPercentage = 20; // Percentage for liquidity pool
    uint256 public stakingRewardsPercentage = 15; // Percentage for staking rewards

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * (10 ** uint256(decimals));
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function setReservePercentage(uint256 _percentage) public onlyOwner {
        reservePercentage = _percentage;
    }

    function setLiquidityPoolPercentage(uint256 _percentage) public onlyOwner {
        liquidityPoolPercentage = _percentage;
    }

    function setStakingRewardsPercentage(uint256 _percentage) public onlyOwner {
        stakingRewardsPercentage = _percentage;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this");
        _;
    }
}
// Part 3: Staking and Rewards Mechanism

contract Staking {
    OrumyxToken public orumyxToken;
    uint256 public stakingRewardRate = 5; // 5% annual rewards

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public lastClaimed;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(address _orumyxToken) {
        orumyxToken = OrumyxToken(_orumyxToken);
    }

    function stake(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(orumyxToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        stakedAmount[msg.sender] += _amount;
        lastClaimed[msg.sender] = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) public {
        require(stakedAmount[msg.sender] >= _amount, "Insufficient staked balance");

        stakedAmount[msg.sender] -= _amount;
        require(orumyxToken.transfer(msg.sender, _amount), "Transfer failed");

        emit Unstaked(msg.sender, _amount);
    }

    function claimReward() public {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No reward available");

        lastClaimed[msg.sender] = block.timestamp;
        require(orumyxToken.transfer(msg.sender, reward), "Transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address _user) public view returns (uint256) {
        uint256 staked = stakedAmount[_user];
        uint256 timeStaked = block.timestamp - lastClaimed[_user];
        uint256 reward = (staked * stakingRewardRate * timeStaked) / (365 days * 100);
        return reward;
    }
}
// Part 4: DAO Governance

contract DAO {
    address public admin;
    uint256 public proposalCount;

    struct Proposal {
        string description;
        uint256 voteCount;
        uint256 endTime;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes; // Track votes by user and proposal

    event ProposalCreated(uint256 proposalId, string description, uint256 endTime);
    event Voted(address indexed user, uint256 proposalId);
    event ProposalExecuted(uint256 proposalId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period is over");
        _;
    }

    modifier proposalEnded(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period not yet ended");
        _;
    }

    constructor() {
        admin = msg.sender;
        proposalCount = 0;
    }

    function createProposal(string memory _description, uint256 _duration) public onlyAdmin {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: _description,
            voteCount: 0,
            endTime: block.timestamp + _duration,
            executed: false
        });

        emit ProposalCreated(proposalCount, _description, proposals[proposalCount].endTime);
    }

    function vote(uint256 _proposalId) public proposalActive(_proposalId) {
        require(!votes[msg.sender][_proposalId], "Already voted");

        votes[msg.sender][_proposalId] = true;
        proposals[_proposalId].voteCount++;

        emit Voted(msg.sender, _proposalId);
    }

    function executeProposal(uint256 _proposalId) public proposalEnded(_proposalId) onlyAdmin {
        require(!proposals[_proposalId].executed, "Proposal already executed");

        proposals[_proposalId].executed = true;

        // Execute actions based on proposal details (e.g., change contract settings)

        emit ProposalExecuted(_proposalId);
    }
}
// Part 5: Staking Mechanism

contract Staking {
    IERC20 public token;
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public stakingStartTime;
    uint256 public totalStaked;

    uint256 public rewardRate = 100; // Example reward rate per second
    uint256 public rewardInterval = 1 days; // Reward given daily

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(IERC20 _token) {
        token = _token;
    }

    function stake(uint256 _amount) public {
        require(_amount > 0, "Amount should be greater than 0");
        token.transferFrom(msg.sender, address(this), _amount);

        stakedAmount[msg.sender] += _amount;
        stakingStartTime[msg.sender] = block.timestamp;
        totalStaked += _amount;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) public {
        require(stakedAmount[msg.sender] >= _amount, "Insufficient staked amount");

        stakedAmount[msg.sender] -= _amount;
        totalStaked -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
    }

    function claimReward() public {
        uint256 reward = calculateReward(msg.sender);
        stakingStartTime[msg.sender] = block.timestamp;

        // Resetting the start time to avoid double reward claim
        token.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address _user) public view returns (uint256) {
        uint256 stakedDuration = block.timestamp - stakingStartTime[_user];
        uint256 reward = (stakedAmount[_user] * rewardRate * stakedDuration) / (1 days);
        return reward;
    }

    function setRewardRate(uint256 _rate) public {
        rewardRate = _rate;
    }
}
// Part 6: Governance Mechanism

contract Governance {
    struct Proposal {
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
        mapping(address => bool) voted;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    uint256 public votingDuration = 3 days;
    uint256 public quorum = 5000 * 10**18; // Minimum quorum for a proposal to be valid

    IERC20 public token;

    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event Voted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);

    constructor(IERC20 _token) {
        token = _token;
    }

    function createProposal(string memory _description) public {
        require(token.balanceOf(msg.sender) >= quorum, "Not enough tokens to propose");

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.endTime = block.timestamp + votingDuration;
        newProposal.executed = false;

        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    function vote(uint256 _proposalId, bool _voteFor) public {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp < proposal.endTime, "Voting period has ended");
        require(!proposal.voted[msg.sender], "You already voted");
        require(token.balanceOf(msg.sender) > 0, "You must hold tokens to vote");

        proposal.voted[msg.sender] = true;

        if (_voteFor) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(_proposalId, msg.sender, _voteFor);
    }

    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp >= proposal.endTime, "Voting period is still active");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Execute proposal logic (e.g., changing tokenomics, adding new features)
            // In this example, no action is taken, but in practice, you could modify state here
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function setVotingDuration(uint256 _duration) public {
        votingDuration = _duration;
    }

    function setQuorum(uint256 _quorum) public {
        quorum = _quorum;
    }
}
// Part 7: Staking and Rewards

contract Staking {
    IERC20 public token;
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public lastClaimed;

    uint256 public rewardRate = 100; // Reward rate per block (example)
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    function stake(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");

        token.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender] += _amount;
        totalStaked += _amount;
        lastClaimed[msg.sender] = block.number;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) public {
        require(stakes[msg.sender] >= _amount, "Insufficient staked balance");

        stakes[msg.sender] -= _amount;
        totalStaked -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
    }

    function claimRewards() public {
        uint256 rewards = calculateRewards(msg.sender);
        require(rewards > 0, "No rewards to claim");

        lastClaimed[msg.sender] = block.number;
        token.transfer(msg.sender, rewards);

        emit Claimed(msg.sender, rewards);
    }

    function calculateRewards(address _user) public view returns (uint256) {
        uint256 stakedAmount = stakes[_user];
        uint256 blocksStaked = block.number - lastClaimed[_user];
        return stakedAmount * rewardRate * blocksStaked;
    }
}
