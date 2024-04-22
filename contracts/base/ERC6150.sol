// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import '../interfaces/IERC6150.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

abstract contract ERC6150 is ERC721, IERC6150 {
    error ArrayLengthNotMatch();
    error ZeroTokenId();
    error NotLeaf();

    mapping(uint256 => uint256) private _parentOf;
    mapping(uint256 => uint256[]) private _childrenOf;
    mapping(uint256 => uint256) private _indexInChildrenArray;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC6150).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function parentOf(
        uint256 tokenId
    ) public view virtual override returns (uint256 parentId) {
        _requireOwned(tokenId);
        parentId = _parentOf[tokenId];
    }

    function childrenOf(
        uint256 tokenId
    ) public view virtual override returns (uint256[] memory childrenIds) {
        _requireOwned(tokenId);
        childrenIds = _childrenOf[tokenId];
    }

    function isRoot(
        uint256 tokenId
    ) public view virtual override returns (bool) {
        _requireOwned(tokenId);
        return _parentOf[tokenId] == 0;
    }

    function isLeaf(
        uint256 tokenId
    ) public view virtual override returns (bool) {
        _requireOwned(tokenId);
        return _childrenOf[tokenId].length == 0;
    }

    function _getIndexInChildrenArray(
        uint256 tokenId
    ) internal view virtual returns (uint256) {
        return _indexInChildrenArray[tokenId];
    }

    function _safeBatchMintWithParent(
        address to,
        uint256 parentId,
        uint256[] memory tokenIds
    ) internal virtual {
        _safeBatchMintWithParent(
            to,
            parentId,
            tokenIds,
            new bytes[](tokenIds.length)
        );
    }

    function _safeBatchMintWithParent(
        address to,
        uint256 parentId,
        uint256[] memory tokenIds,
        bytes[] memory datas
    ) internal virtual {
        if (tokenIds.length != datas.length) revert ArrayLengthNotMatch();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMintWithParent(to, parentId, tokenIds[i], datas[i]);
        }
    }

    function _safeMintWithParent(
        address to,
        uint256 parentId,
        uint256 tokenId
    ) internal virtual {
        _safeMintWithParent(to, parentId, tokenId, "");
    }

    function _safeMintWithParent(
        address to,
        uint256 parentId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        if (tokenId == 0) revert ZeroTokenId();
        if (parentId != 0) _requireOwned(parentId);

        _parentOf[tokenId] = parentId;
        _indexInChildrenArray[tokenId] = _childrenOf[parentId].length;
        _childrenOf[parentId].push(tokenId);

        _safeMint(to, tokenId, data);
        emit Minted(msg.sender, to, parentId, tokenId);
    }

    function _safeBurn(uint256 tokenId) internal virtual {
        _requireOwned(tokenId);
        if (!isLeaf(tokenId)) revert NotLeaf();

        uint256 parent = _parentOf[tokenId];
        uint256 lastTokenIndex = _childrenOf[parent].length - 1;
        uint256 targetTokenIndex = _indexInChildrenArray[tokenId];
        uint256 lastIndexToken = _childrenOf[parent][lastTokenIndex];
        if (lastTokenIndex > targetTokenIndex) {
            _childrenOf[parent][targetTokenIndex] = lastIndexToken;
            _indexInChildrenArray[lastIndexToken] = targetTokenIndex;
        }

        delete _childrenOf[parent][lastIndexToken];
        delete _indexInChildrenArray[tokenId];
        delete _parentOf[tokenId];

        _burn(tokenId);
    }
}