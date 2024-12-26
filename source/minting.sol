function mint(address to, uint256 amount) external onlyOwner {
    orumyxToken.mint(to, amount);
}

function burn(address from, uint256 amount) external onlyOwner {
    orumyxToken.burn(from, amount);
}
