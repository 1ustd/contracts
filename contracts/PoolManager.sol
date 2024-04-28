// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import './interfaces/IPoolManager.sol';
import './interfaces/IUserRegistar.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol';

contract PoolManager is IPoolManager, Ownable, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    uint24 public constant HUNDRED_PERCENT = 1000000; // 100%

    uint24 public referralFee;

    IERC20 public immutable usdt;
    IUserRegistar public immutable userRegistar;
    VRFCoordinatorV2Interface public immutable vrfCoordinator;

    // params for vrfCoordinator.requestRandomWords function
    bytes32 public keyHash;
    uint64 public subId;
    uint16 public minRequestConfirmations = 3;
    uint32 public callbackGasLimit = 100000;

    // if use subgraph, can remove
    mapping(address referrer => uint256) public referralRewardAccumulated;
    mapping(address referrer => uint256) public referralRewardAccured;
    mapping(bytes32 poolId => mapping(uint256 roundId => mapping(uint32 ticket => address owner))) public getTicketOwner;

    // if use subgraph, can remove
    mapping(address user => ParticipationRecord[]) private _userParticipationRecords;

    mapping(bytes32 poolId => mapping(uint256 roundId => uint32[])) private _soldTickets;
    mapping(uint256 vrfRequestId => VRFRequestInfo) private _vrfRequestInfoMap;
    mapping(bytes32 poolId => PoolInfo) private _poolInfoMap;
    bytes32[] private _poolIds;

    constructor(
        uint24 referralFee_,
        address usdt_,
        address userRegistar_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint64 subId_
    ) Ownable(msg.sender) VRFConsumerBaseV2(vrfCoordinator_) {
        referralFee = referralFee_;
        usdt = IERC20(usdt_);
        userRegistar = IUserRegistar(userRegistar_);
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        keyHash = keyHash_;
        subId = subId_;
    }

    function updateKeyHash(bytes32 newKeyHash) external onlyOwner {
        keyHash = newKeyHash;
    }

    function updateSubId(uint64 newSubId) external onlyOwner {
        subId = newSubId;
    }

    function updateMinRequestConfirmations(uint16 newMinRequestConfirmations) external onlyOwner {
        minRequestConfirmations = newMinRequestConfirmations;
    }

    function updateCallbackGasLimit(uint32 newGasLimit) external onlyOwner {
        callbackGasLimit = newGasLimit;
    }

    function updateReferralFee(uint24 newReferralFee) external onlyOwner {
        if (newReferralFee >= HUNDRED_PERCENT) revert OverHundredPercent();
        emit ReferralFeeUpdated(referralFee, newReferralFee);
        referralFee = newReferralFee;
    }

    function getAllPoolIds() external view returns (bytes32[] memory poolIds) {
        return _poolIds;
    }

    function getPoolInfo(bytes32 poolId) external view returns (
        uint128 prize, 
        uint128 totalTickets, 
        uint128 pricePerTicket,
        uint128 roundDuration,
        uint128 roundGapTime,
        uint256 currentRound
    ) {
        PoolInfo memory poolInfo = _poolInfoMap[poolId];
        prize = poolInfo.prize;
        totalTickets = poolInfo.totalTickets;
        pricePerTicket = poolInfo.pricePerTicket;
        roundDuration = poolInfo.roundDuration;
        roundGapTime = poolInfo.roundGapTime;
        currentRound = poolInfo.roundInfos.length;
    }

    function getRoundInfo(bytes32 poolId, uint256 roundId) external view returns (
        uint128 startTime,
        uint128 endTime,
        uint128 leftTickets,
        uint256 vrfRequestId,
        uint32 winNumber,
        bool isClaimed
    ) {
        RoundInfo memory roundInfo = _poolInfoMap[poolId].roundInfos[roundId - 1];
        startTime = roundInfo.startTime;
        endTime = roundInfo.endTime;
        leftTickets = roundInfo.leftTickets;
        vrfRequestId = roundInfo.vrfRequestId;
        winNumber = roundInfo.winNumber;
        isClaimed = roundInfo.isClaimed;
    }

    function getSoldTickets(bytes32 poolId, uint256 roundId) external view returns (uint32[] memory) {
        return _soldTickets[poolId][roundId];
    }

    function getAllParticipationRecords(address user) external view returns (ParticipationRecord[] memory) {
        return _userParticipationRecords[user];
    }

    function getParticipationRecordsByPoolRound(address user, bytes32 poolId, uint256 roundId) external view returns (ParticipationRecord[] memory records) {
        ParticipationRecord[] memory allRecords = _userParticipationRecords[user];
        ParticipationRecord[] memory tempRecords = new ParticipationRecord[](allRecords.length);
        uint256 realLength;
        for (uint256 i = 0; i < allRecords.length; i++) {
            ParticipationRecord memory record = allRecords[i];
            if (poolId == record.poolId && roundId == record.roundId) {
                tempRecords[realLength] = record;
                realLength++;
            }
        }

        records = new ParticipationRecord[](realLength);
        for (uint256 i = 0; i < realLength; i++) {
            records[i] = tempRecords[i];
        }
    }

    function getWonParticipationRecords(address user) public view returns (ParticipationRecord[] memory records, uint256 totalPrizes) {
        ParticipationRecord[] memory allRecords = _userParticipationRecords[user];
        ParticipationRecord[] memory tempRecords = new ParticipationRecord[](allRecords.length);
        uint256 realLength;
        for (uint256 i = 0; i < allRecords.length; i++) {
            ParticipationRecord memory record = allRecords[i];
            bytes32 poolId = record.poolId; 
            uint256 roundId = record.roundId;
            uint32 winNumber = _poolInfoMap[poolId].roundInfos[roundId - 1].winNumber;
            for (uint256 j = 0; j < record.ticketsCount; j++) {
                if (winNumber == record.tickets[j]) {
                    uint32[] memory winningTicket = new uint32[](1);
                    winningTicket[0] = winNumber;
                    tempRecords[realLength] = ParticipationRecord(poolId, roundId, record.timestamp, 1, winningTicket);
                    totalPrizes += _poolInfoMap[poolId].prize;
                    realLength++;
                    break;
                }
            }
            
        }
        records = new ParticipationRecord[](realLength);
        for (uint256 i = 0; i < realLength; i++) {
            records[i] = tempRecords[i];
        }
    }

    function getUnclaimedPrizes(address user) external view returns (bytes32[] memory poolIds, uint256[] memory roundIds, uint256 totalPrizes) {
        (ParticipationRecord[] memory wonRecords, ) = getWonParticipationRecords(user);
        bytes32[] memory tempPoolIds = new bytes32[](wonRecords.length);
        uint256[] memory tempRoundIds = new uint256[](wonRecords.length);
        uint256 resultCount;
        for (uint256 i = 0; i < wonRecords.length; i++) {
            ParticipationRecord memory record = wonRecords[i];
            bytes32 poolId = record.poolId; 
            uint256 roundId = record.roundId;
            if (!_poolInfoMap[poolId].roundInfos[roundId - 1].isClaimed) {
                totalPrizes += _poolInfoMap[poolId].prize;
                tempPoolIds[resultCount] = poolId;
                tempRoundIds[resultCount] = roundId;
                resultCount++;
            }
        }

        poolIds = new bytes32[](resultCount);
        roundIds = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            poolIds[i] = tempPoolIds[i];
            roundIds[i] = tempRoundIds[i];
        }
    }

    function createPool(
        uint8 totalTicketsExp,
        uint128 prize,
        uint128 pricePerTicket,
        uint128 roundDuration,
        uint128 roundGapTime,
        uint128 startTime
    ) external onlyOwner returns (bytes32 poolId) {
        if (totalTicketsExp == 0) revert ZeroTicketsExp();
        if (prize == 0) revert ZeroPrize();
        if (roundDuration == 0) revert ZeroRoundDuration();
        if (startTime < block.timestamp) revert InvalidStartTime();

        uint128 totalTickets = uint128(10 ** totalTicketsExp);
        poolId = keccak256(
            abi.encode(
                prize,
                totalTickets,
                pricePerTicket,
                roundDuration,
                roundGapTime
            )
        );
        if (_poolInfoMap[poolId].prize > 0) revert PoolExists();

        _poolInfoMap[poolId].prize = prize;
        _poolInfoMap[poolId].totalTickets = totalTickets;
        _poolInfoMap[poolId].pricePerTicket = pricePerTicket;
        _poolInfoMap[poolId].roundDuration = roundDuration;
        _poolInfoMap[poolId].roundGapTime = roundGapTime;

        RoundInfo memory newRoundInfo = RoundInfo({
            startTime: startTime,
            endTime: startTime + roundDuration,
            leftTickets: totalTickets,
            vrfRequestId: 0,
            winNumber: 0,
            isClaimed: false
        });
        _poolInfoMap[poolId].roundInfos.push(newRoundInfo);
        _poolIds.push(poolId);
        emit PoolCreated(
            prize,
            totalTickets,
            pricePerTicket,
            roundDuration,
            roundGapTime,
            poolId
        );
        emit NewRoundOpened(poolId, 1, startTime, newRoundInfo.endTime);
    }

    function buyTickets(
        bytes32 poolId,
        uint256 roundId,
        uint32[] calldata tickets
    ) external {
        if (tickets.length == 0) revert NoTicketSpecified();

        PoolInfo memory poolInfo = _poolInfoMap[poolId];
        RoundInfo memory roundInfo = poolInfo.roundInfos[roundId - 1];
        if (block.timestamp < roundInfo.startTime) revert RoundNotStart();
        if (block.timestamp >= roundInfo.endTime) revert RoundEnded();
        if (tickets.length > roundInfo.leftTickets) revert NotEnoughTicketsLeft();

        for (uint256 i = 0; i < tickets.length; i++) {
            if (tickets[i] == 0 || tickets[i] > poolInfo.totalTickets)
                revert InvalidTicket(tickets[i]);
            if (getTicketOwner[poolId][roundId][tickets[i]] != address(0))
                revert TicketSold(tickets[i]);
            getTicketOwner[poolId][roundId][tickets[i]] = msg.sender;
            _soldTickets[poolId][roundId].push(tickets[i]);
        }

        _userParticipationRecords[msg.sender].push(ParticipationRecord({
            poolId: poolId,
            roundId: roundId,
            timestamp: block.timestamp,
            ticketsCount: tickets.length,
            tickets: tickets
        }));

        uint128 need2Pay = uint128(tickets.length) * poolInfo.pricePerTicket;
        usdt.safeTransferFrom(msg.sender, address(this), need2Pay);

        address referrer = userRegistar.getReferrer(msg.sender);
        if (referrer != address(0)) {
            uint128 referralReward = (need2Pay * uint128(referralFee)) /
                uint128(HUNDRED_PERCENT);
            referralRewardAccured[referrer] += referralReward;
            referralRewardAccumulated[referrer] += referralReward;
        }

        roundInfo.leftTickets -= uint128(tickets.length);

        emit TicketsSold(msg.sender, poolId, roundId, tickets);

        if (roundInfo.leftTickets == 0) {
            uint256 requestId = vrfCoordinator.requestRandomWords(keyHash, subId, minRequestConfirmations, callbackGasLimit, 1);
            _vrfRequestInfoMap[requestId] = VRFRequestInfo(poolId, roundId);
            roundInfo.vrfRequestId = requestId;
            roundInfo.endTime = uint128(block.timestamp);

            uint128 nextStartTime = uint128(block.timestamp) + poolInfo.roundGapTime;
            uint128 nextEndTime = nextStartTime + poolInfo.roundDuration;
            RoundInfo memory nextRoundInfo = RoundInfo({
                startTime: nextStartTime,
                endTime: nextEndTime,
                leftTickets: poolInfo.totalTickets,
                vrfRequestId: 0,
                winNumber: 0,
                isClaimed: false
            });
            _poolInfoMap[poolId].roundInfos.push(nextRoundInfo);
            uint256 newRoundId = _poolInfoMap[poolId].roundInfos.length;

            emit NewRoundOpened(poolId, newRoundId, nextStartTime, nextEndTime);
        }

        _poolInfoMap[poolId].roundInfos[roundId - 1] = roundInfo;
    }

    function drawEndedRoundAndOpenNewRound(bytes32 poolId) external {
        PoolInfo memory poolInfo = _poolInfoMap[poolId];
        uint256 roundId = poolInfo.roundInfos.length;
        if (roundId == 0) revert PoolNotFound();

        RoundInfo memory roundInfo = _poolInfoMap[poolId].roundInfos[roundId - 1];
        if (block.timestamp < roundInfo.endTime) revert NotEnded();
        if (roundInfo.vrfRequestId > 0) revert AlreadyDrawn();

        uint256 requestId = vrfCoordinator.requestRandomWords(keyHash, subId, minRequestConfirmations, callbackGasLimit, 1);
        _vrfRequestInfoMap[requestId] = VRFRequestInfo(poolId, roundId);
        roundInfo.vrfRequestId = requestId;
        _poolInfoMap[poolId].roundInfos[roundId - 1] = roundInfo;

        uint128 nextStartTime = uint128(block.timestamp) + poolInfo.roundGapTime;
        uint128 nextEndTime = nextStartTime + poolInfo.roundDuration;
        RoundInfo memory nextRoundInfo = RoundInfo({
            startTime: nextStartTime,
            endTime: nextEndTime,
            leftTickets: poolInfo.totalTickets,
            vrfRequestId: 0,
            winNumber: 0,
            isClaimed: false
        });
        _poolInfoMap[poolId].roundInfos.push(nextRoundInfo);
        uint256 newRoundId = _poolInfoMap[poolId].roundInfos.length;
        emit NewRoundOpened(poolId, newRoundId, nextStartTime, nextEndTime);
    }

    function claimPrizes(
        address to,
        bytes32[] calldata poolIds,
        uint256[] calldata roundIds
    ) external {
        if (poolIds.length != roundIds.length) revert DifferentArrayLength();
        uint256 totalPrize;
        for (uint256 i = 0; i < poolIds.length; i++) {
            uint32 winNumber = _poolInfoMap[poolIds[i]].roundInfos[roundIds[i] - 1].winNumber;
            bool isClaimed = _poolInfoMap[poolIds[i]].roundInfos[roundIds[i] - 1].isClaimed;
            if (winNumber == 0) revert ZeroWinNumber();
            if (isClaimed) revert AlreadyClaimed();
            if (msg.sender != getTicketOwner[poolIds[i]][roundIds[i]][winNumber]) revert NotWinner();
            totalPrize += _poolInfoMap[poolIds[i]].prize;
            _poolInfoMap[poolIds[i]].roundInfos[roundIds[i] - 1].isClaimed = true;
            emit PrizeClaimed(poolIds[i], roundIds[i]);
        }
        usdt.safeTransfer(to, totalPrize);
    }

    function collectReferralReward(address to) external {
        uint256 accured = referralRewardAccured[msg.sender];
        usdt.safeTransfer(to, accured);
        referralRewardAccured[msg.sender] = 0;
        emit ReferralRewardCollected(msg.sender, accured);
    }

    function withdrawUsdt(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        usdt.safeTransfer(to, amount);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        VRFRequestInfo memory requestInfo = _vrfRequestInfoMap[requestId];
        uint256 winNumber = randomWords[0] % _poolInfoMap[requestInfo.poolId].totalTickets + 1;
        _poolInfoMap[requestInfo.poolId].roundInfos[requestInfo.roundId - 1].winNumber = uint32(winNumber);
    }
}