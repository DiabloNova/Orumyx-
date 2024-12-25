// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin contracts for token functionality
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoToken is ERC20, Ownable {
    // Variables for token supply and reserve backing
    uint256 private _initialSupply = 1000000 * (10 ** uint256(decimals()));
    address public reserveAddress;

    // Event for minting tokens
    event TokensMinted(address to, uint256 amount);

    constructor(address _reserveAddress) ERC20("CryptoToken", "CTK") {
        reserveAddress = _reserveAddress;
        _mint(msg.sender, _initialSupply);  // Mint initial supply to contract deployer
    }

    // Function to mint new tokens (controlled by the owner)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    // Function to update the reserve address
    function updateReserveAddress(address newReserve) external onlyOwner {
        reserveAddress = newReserve;
    }

    // Override _beforeTokenTransfer to enforce rules for token distribution (if needed)
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }
}
