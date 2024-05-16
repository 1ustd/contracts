// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

interface IVRFConsumer {
    function requestRandomWords() external returns (uint256 requestId);
}