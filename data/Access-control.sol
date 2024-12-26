// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessControl {
    address public admin;
    mapping(address => bool) public authorizedUsers;
    event UserAuthorized(address indexed user, uint256 timestamp);
    event UserRevoked(address indexed user, uint256 timestamp);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedUsers[msg.sender], "You are not authorized to perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Function to authorize a user
    function authorizeUser(address user) public onlyAdmin {
        authorizedUsers[user] = true;
        emit UserAuthorized(user, block.timestamp);
    }

    // Function to revoke a user's authorization
    function revokeUser(address user) public onlyAdmin {
        authorizedUsers[user] = false;
        emit UserRevoked(user, block.timestamp);
    }

    // Function to check if a user is authorized
    function isUserAuthorized(address user) public view returns (bool) {
        return authorizedUsers[user];
    }
}
