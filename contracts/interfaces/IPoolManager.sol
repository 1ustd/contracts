// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import './IUserRegistar.sol';
import './IVRFConsumer.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPoolManager {
    error InvalidMsgSender();
    error NotRegistered();
    error OverHundredPercent();
    error ZeroAddress();
    error ZeroTicketsExp();
    error ZeroPrize();
    error ZeroRoundDuration();
    error PoolExists();
    error PoolNotFound();
    error InvalidStartTime();
    error NoTicketSpecified();
    error TooManyTickets();
    error RoundNotStart();
    error RoundEnded();
    error NotEnoughTicketsLeft();
    error TicketSold(uint32 ticket);
    error InvalidTicket(uint32 ticket);
    error DifferentArrayLength();
    error ZeroWinNumber();
    error NotWinner();
    error AlreadyClaimed();
    error NotEnded();
    error AlreadyDrawn();

    event ReferralFeeUpdated(uint24 oldReferralFee, uint24 newReferralFee);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event PoolCreated(
        uint128 prize,
        uint128 totalTickets, 
        uint128 pricePerTicket, 
        uint128 roundDuration, 
        uint128 roundGapTime,
        bytes32 poolId
    );
    event NewRoundOpened(
        bytes32 poolId,
        uint256 roundId,
        uint128 startTime,
        uint128 endTime
    );
    event TicketsSold(
        address indexed owner,
        bytes32 poolId,
        uint256 roundId,
        uint32[] tickets
    );
    event PrizeClaimed(
        bytes32 poolId,
        uint256 roundId
    );
    event ReferralRewardCollected(address indexed referrer, uint256 amount);

    struct PoolInfo {
        uint128 prize;
        uint128 totalTickets;
        uint128 pricePerTicket;
        uint128 roundDuration;
        uint128 roundGapTime;
        RoundInfo[] roundInfos;
    }

    struct RoundInfo {
        uint128 startTime;
        uint128 endTime;
        uint128 leftTickets;
        uint256 vrfRequestId;
        uint32 winNumber;
        bool isClaimed;
    }

    struct ParticipationRecord {
        bytes32 poolId;
        uint256 roundId;
        uint256 timestamp;
        uint256 ticketsCount;
        uint32[] tickets;
    }

    struct VRFRequestInfo {
        bytes32 poolId;
        uint256 roundId;
    }

    function HUNDRED_PERCENT() external view returns (uint24);

    function referralFee() external view returns (uint24);

    function usdt() external view returns (IERC20);

    function userRegistar() external view returns (IUserRegistar);

    function vrfConsumer() external view returns (IVRFConsumer);

    function getTicketOwner(bytes32 poolId, uint256 roundId, uint32 ticket) external view returns (address);

    function referralRewardAccured(address referrer) external view returns (uint256);

    function referralRewardAccumulated(address referrer) external view returns (uint256);

    function getAllPoolIds() external view returns (bytes32[] memory poolIds);

    function getPoolInfo(bytes32 poolId) external view returns (
        uint128 prize, 
        uint128 totalTickets, 
        uint128 pricePerTicket, 
        uint128 roundDuration,
        uint128 roundGapTime,
        uint256 currentRound
    );

    function getRoundInfo(bytes32 poolId, uint256 roundId) external view returns (
        uint128 startTime,
        uint128 endTime,
        uint128 leftTickets,
        uint256 vrfRequestId,
        uint32 winNumber,
        bool isClaimed
    );

    function getSoldTickets(bytes32 poolId, uint256 roundId) external view returns (uint32[] memory soldTickets);

    function getAllParticipationRecords(address user) external view returns (ParticipationRecord[] memory);

    function getParticipationRecordsByPoolRound(address user, bytes32 poolId, uint256 roundId) external view returns (ParticipationRecord[] memory);

    function getWonParticipationRecords(address user) external view returns (ParticipationRecord[] memory, uint256 totalPrizes);

    function getUnclaimedPrizes(address user) external view returns (bytes32[] memory poolIds, uint256[] memory roundIds, uint256 totalPrizes);

    function updateReferralFee(uint24 newReferralFee) external;

    function setVRFConsumer(address vrfConsumer_) external;

    function createPool(
        uint8 totalTicketsExp,
        uint128 prize,
        uint128 pricePerTicket,
        uint128 roundDuration,
        uint128 roundGapTime,
        uint128 startTime
    ) external returns (bytes32 poolId);

    function buyTickets(bytes32 poolId, uint256 roundId, uint32[] calldata tickets) external;

    function drawEndedRoundAndOpenNewRound(bytes32 poolId) external;

    function claimPrizes(address to, bytes32[] calldata poolIds, uint256[] calldata roundIds) external;

    function collectReferralReward(address to) external;

    function withdrawUsdt(address to, uint256 amount) external;
}