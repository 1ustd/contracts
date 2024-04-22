// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import '../interfaces/IERC6150Enumerable.sol';
import './ERC6150.sol';

abstract contract ERC6150Enumerable is ERC6150, IERC6150Enumerable {
    error WrongParent();

    function childrenCountOf(
        uint256 parentId
    ) external view override returns (uint256) {
        return childrenOf(parentId).length;
    }

    function childOfParentByIndex(
        uint256 parentId,
        uint256 index
    ) external view override returns (uint256) {
        uint256[] memory children = childrenOf(parentId);
        return children[index];
    }

    function indexInChildrenEnumeration(
        uint256 parentId,
        uint256 tokenId
    ) external view override returns (uint256) {
        if (parentOf(tokenId) != parentId) revert WrongParent();
        return _getIndexInChildrenArray(tokenId);
    }
}
