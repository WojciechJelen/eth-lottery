// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// CEI: checks, effetcs, interactions

/**
 * @title Raffle
 * @author Wojciech Jelen
 * @notice This contract is for creating a raffle and learning about Chainlink VRF and Chainlink Automations
 * @dev Imlemepnts Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    error Raffle__NotEnoughEthToEnterRaffle();
    error Raffle__TransferFailed(address to, uint256 amount);
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 participants,
        RaffleState state
    );

    /** Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING_WINNER
    }

    /** State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUMBER_OF_RANDOM_NUMEBRS = 1;

    /** Immutable variables */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address[] private s_participants;
    uint256 private s_lastTimeTimestamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event EnteredRaffle(address indexed participant);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gaslane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gaslane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaflle() external payable {
        if (msg.value < i_entranceFee)
            revert Raffle__NotEnoughEthToEnterRaffle();

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_participants.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that Chainlink Automation nodes call to see,
     * if the upkeep is needed. The follwoing requirements must be met:
     * 1. The raffle must be OPEN
     * 2. The interval must have passed
     * 3. The raffle must have at least one participant (contract must have funds)
     * 4. (Implicit) The subscription is funded with LINK
     *
     * @return upkeepNeeded - true if the upkeep is needed
     * @return
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeTimestamp) >=
            i_interval;
        bool raffleIsOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasParticipants = s_participants.length > 0;

        upkeepNeeded =
            timeHasPassed &&
            raffleIsOpen &&
            hasParticipants &&
            hasBalance;

        return (upkeepNeeded, "0x0");
    }

    // 1. get the random number
    // 2. pick the winner using the random number
    // 3. Be automatically called by Chainlink VRF
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("0x0");

        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_participants.length,
                s_raffleState
            );
        }

        if (block.timestamp - s_lastTimeTimestamp < i_interval) {
            revert("Raffle: Not enough time has passed");
        }

        /**
         * @dev sets raffle state to calculating winner, preventing from entering raffle
         */
        s_raffleState = RaffleState.CALCULATING_WINNER;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUMBER_OF_RANDOM_NUMEBRS
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 randomNumber = randomWords[0];
        uint256 winnerIndex = randomNumber % s_participants.length;
        address winner = s_participants[winnerIndex];
        s_recentWinner = winner;

        /**
         * @dev Opens raffle after winner is picked
         */
        s_raffleState = RaffleState.OPEN;
        /**
         * @dev Clears participants array
         */

        // delete s_participants;
        s_participants = new address[](0);
        // resets the timestamp
        s_lastTimeTimestamp = block.timestamp;
        emit WinnerPicked(winner);

        (bool success, ) = winner.call{value: address(this).balance}("");

        if (!success) {
            revert Raffle__TransferFailed({
                to: winner,
                amount: address(this).balance
            });
        }
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getParticipants() public view returns (address[] memory) {
        return s_participants;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }
}
