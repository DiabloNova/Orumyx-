// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OrumyxToken {
    string public name = "Orumyx";
    string public symbol = "ORX";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 1000000000 * 10**18; // 1 billion ORX tokens (with decimals)

    // Reserves
    uint256 public liquidityReserve;
    uint256 public collateralReserve;
    uint256 public governanceReserve;
    uint256 public teamReserve;
    uint256 public partnerReserve;
    uint256 public marketingReserve;

    // Mapping for balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokensBurned(address indexed burner, uint256 value);

    constructor() {
        // Initial distribution
        liquidityReserve = MAX_SUPPLY * 40 / 100;
        collateralReserve = MAX_SUPPLY * 25 / 100;
        governanceReserve = MAX_SUPPLY * 15 / 100;
        teamReserve = MAX_SUPPLY * 10 / 100;
        partnerReserve = MAX_SUPPLY * 5 / 100;
        marketingReserve = MAX_SUPPLY * 5 / 100;

        // Minting the initial supply to the contract owner
        totalSupply = liquidityReserve + collateralReserve + governanceReserve + teamReserve + partnerReserve + marketingReserve;
        balanceOf[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ERC20 transfer function
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // ERC20 approve function
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // ERC20 transferFrom function
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(allowance[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Function to mint new tokens
    function mint(address account, uint256 amount) public returns (bool) {
        require(totalSupply + amount <= MAX_SUPPLY, "ERC20: max supply exceeded");

        totalSupply += amount;
        balanceOf[account] += amount;

        emit Transfer(address(0), account, amount);
        return true;
    }

    // Function to burn tokens
    function burn(uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20: burn amount exceeds balance");

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;

        emit TokensBurned(msg.sender, amount);
        return true;
    }
}
