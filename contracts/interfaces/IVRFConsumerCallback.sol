// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

interface IVRFConsumerCallback {
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external;
}