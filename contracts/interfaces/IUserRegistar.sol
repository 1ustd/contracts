// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

interface IUserRegistar {
    error UserAlreadyRegisted(address user);
    error ForbidTransfer();

    event SignedUp(address indexed user, uint256 id, uint256 referrerId);

    function getUserId(address user) external view returns (uint256 id);

    function getReferrer(address user) external view returns (address referrer);

    function signUp(uint256 referrerId) external;
}