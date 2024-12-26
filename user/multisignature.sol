// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigGovernance {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredSignatures;
    mapping(uint256 => Proposal) public proposals;
    
    struct Proposal {
        uint256 id;
        address target;
        uint256 value;
        string data;
        uint256 approvalCount;
        mapping(address => bool) approvals;
        bool executed;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier notExecuted(uint256 proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredSignatures) {
        require(_owners.length >= _requiredSignatures, "More owners needed");
        owners = _owners;
        requiredSignatures = _requiredSignatures;

        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
    }

    function submitProposal(address target, uint256 value, string memory data) external onlyOwner {
        uint256 proposalId = uint256(keccak256(abi.encodePacked(target, value, data, block.timestamp)));
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.target = target;
        proposal.value = value;
        proposal.data = data;
    }

    function approveProposal(uint256 proposalId) external onlyOwner notExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.approvals[msg.sender], "Already approved");

        proposal.approvals[msg.sender] = true;
        proposal.approvalCount++;

        if (proposal.approvalCount >= requiredSignatures) {
            executeProposal(proposalId);
        }
    }

    function executeProposal(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.approvalCount >= requiredSignatures, "Not enough approvals");

        (bool success, ) = proposal.target.call{value: proposal.value}(bytes(proposal.data));
        require(success, "Proposal execution failed");

        proposal.executed = true;
    }

    // Allow the contract to receive ether for use in proposals
    receive() external payable {}
}
