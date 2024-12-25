// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractUpdates {
    address public owner;
    bool public contractUpdated;
    string public contractVersion;

    event ContractUpdated(address indexed owner, string version, uint256 timestamp);
    event ContractVersionChanged(string oldVersion, string newVersion, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can update the contract");
        _;
    }

    constructor() {
        owner = msg.sender;
        contractUpdated = false;
        contractVersion = "1.0";
    }

    // Function to update the contract logic or state
    function updateContract(string memory newVersion) public onlyOwner {
        string memory oldVersion = contractVersion;
        contractVersion = newVersion;
        contractUpdated = true;
        emit ContractVersionChanged(oldVersion, newVersion, block.timestamp);
        emit ContractUpdated(owner, newVersion, block.timestamp);
    }

    // Function to revert the contract to its previous version if needed
    function revertUpdate(string memory previousVersion) public onlyOwner {
        string memory oldVersion = contractVersion;
        contractVersion = previousVersion;
        contractUpdated = false;
        emit ContractVersionChanged(oldVersion, previousVersion, block.timestamp);
    }

    // Function to get the current version of the contract
    function getContractVersion() public view returns (string memory) {
        return contractVersion;
    }
}
