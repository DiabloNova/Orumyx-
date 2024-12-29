// contracts/Vault.sol

pragma solidity ^0.8.0;

contract OrumyxVault {
    // Token details
    string public name = "Orumyx";
    string public symbol = "ORX";
    uint256 public totalSupply = 1000000000 * 10**18; // 1 billion ORX tokens
    uint8 public decimals = 18;

    // Mapping to store token balances
    mapping(address => uint256) public balanceOf;

    // Mapping for allowance
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Constructor to mint initial supply
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // Function to transfer tokens
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // Function to approve allowance
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Function to transfer tokens from another account
    function transferFrom(address owner, address recipient, uint256 amount) public returns (bool) {
        require(allowance[owner][msg.sender] >= amount, "Allowance insufficient");
        require(balanceOf[owner] >= amount, "Owner balance insufficient");

        balanceOf[owner] -= amount;
        balanceOf[recipient] += amount;
        allowance[owner][msg.sender] -= amount;

        emit Transfer(owner, recipient, amount);
        return true;
    }

    // Function to increase allowance
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowance[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    // Function to decrease allowance
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Insufficient allowance to subtract");
        allowance[msg.sender][spender] = currentAllowance - subtractedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }
}
