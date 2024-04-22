// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import './base/ERC6150Enumerable.sol';
import './interfaces/IUserRegistar.sol';

contract UserRegistar is IUserRegistar, ERC6150Enumerable {

    mapping(address => uint256) public getUserId;

    uint256 private _nextId = 1;

    constructor() ERC6150("OneUsdt User ID", "OU-UID") {}

    function signUp(uint256 referrerId) external {
        if (getUserId[msg.sender] > 0) revert UserAlreadyRegisted(msg.sender);
        _safeMintWithParent(msg.sender, referrerId, _nextId);
        getUserId[msg.sender] = _nextId;
        _nextId++;
    }

    function getReferrer(address user) external view returns (address referrer) {
        try this.parentOf(getUserId[user]) returns (uint256 parentId) {
            if (parentId > 0) {
                referrer = this.ownerOf(parentId);
            }
        } catch {}
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
        _updateUserId(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        super.safeTransferFrom(from, to, tokenId, data);
        _updateUserId(from, to, tokenId);
    }

    function _updateUserId(address from, address to, uint256 id) internal {
        if (getUserId[to] > 0) revert UserAlreadyRegisted(to);
        delete getUserId[from];
        getUserId[to] = id;
    }
}