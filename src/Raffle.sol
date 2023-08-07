// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/**
 * @title Raffle
 * @author Wojciech Jelen
 * @notice This contract is for creating a raffle and learning about Chainlink VRF and Chainlink Automations
 * @dev Imlemepnts Chainlink VRFv2
 */
contract Raffle {
    error Raffle__NotEnoughEthToEnterRaffle(uint256 required, uint256 provided);

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUMBER_OF_RANDOM_NUMEBRS = 1;

    uint256 private immutable i_entranceFee = 0.1 ether;
    uint256 private immutable i_interval = 1 days;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address[] private s_participants;
    uint256 private s_lastTimeTimestamp;

    /** Events */
    event EnteredRaffle(address indexed participant);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gaslane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gaslane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeTimestamp = block.timestamp;
    }

    function enterRaflle() external payable {
        if (msg.value >= i_entranceFee)
            revert Raffle__NotEnoughEthToEnterRaffle({
                required: i_entranceFee,
                provided: msg.value
            });
        s_participants.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // 1. get the random number
    // 2. pick the winner using the random number
    // 3. Be automatically called by Chainlink VRF
    function pickWinner() external {
        if (block.timestamp - s_lastTimeTimestamp < i_interval) {
            revert("Raffle: Not enough time has passed");
        }

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUMBER_OF_RANDOM_NUMEBRS
        );
    }

    function getEntranceFee() public pure returns (uint256) {
        return i_entranceFee;
    }

    function getParticipants() public view returns (address[] memory) {
        return s_participants;
    }
}
