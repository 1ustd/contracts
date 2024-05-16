// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import './interfaces/IVRFConsumer.sol';
import './interfaces/IVRFConsumerCallback.sol';
import '@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol';
import '@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol';

contract VRFConsumer is IVRFConsumer, VRFConsumerBaseV2Plus {
    error InvalidMsgSender();

    address public poolManager;
    bytes32 public keyHash;
    uint256 public subscriptionId;
    uint16 public requestConfirmations;
    uint32 public callbackGasLimit;

    constructor(
        address poolManager_,
        address vrfCoordinator_, 
        bytes32 keyHash_,
        uint256 subscriptionId_,
        uint16 requestConfirmations_,
        uint32 callbackGasLimit_
    ) VRFConsumerBaseV2Plus(vrfCoordinator_) {
        poolManager = poolManager_;
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        requestConfirmations = requestConfirmations_;
        callbackGasLimit = callbackGasLimit_;
    }

    function updateKeyHash(bytes32 newKeyHash) external onlyOwner {
        keyHash = newKeyHash;
    }

    function updateSubscriptionId(uint64 newSubscriptionId) external onlyOwner {
        subscriptionId = newSubscriptionId;
    }

    function updateRequestConfirmations(uint16 newRequestConfirmations) external onlyOwner {
        requestConfirmations = newRequestConfirmations;
    }

    function updateCallbackGasLimit(uint32 newGasLimit) external onlyOwner {
        callbackGasLimit = newGasLimit;
    }

    function requestRandomWords() external returns (uint256 requestId) {
        if (msg.sender != poolManager) revert InvalidMsgSender();
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        IVRFConsumerCallback(poolManager).fulfillRandomWords(requestId, randomWords);
    }
}