enum ProposalType { FundAllocation, ContractUpgrade, Other }
ProposalType public proposalType;

if (proposalType == ProposalType.FundAllocation) {
    // Transfer funds to a designated address
} else if (proposalType == ProposalType.ContractUpgrade) {
    // Upgrade the contract (add a function to handle contract upgrades)
}
