// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title Raffle
 * @author Wojciech Jelen
 * @notice This contract is for creating a raffle and learning about Chainlink VRF and Chainlink Automations
 * @dev Imlemepnts Chainlink VRFv2
 */
contract Raffle {
    error Raffle__NotEnoughEthToEnterRaffle(uint256 required, uint256 provided);

    uint256 private immutable i_entranceFee = 0.1 ether;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaflle() external payable {
        if (msg.value >= i_entranceFee)
            revert Raffle__NotEnoughEthToEnterRaffle({
                required: i_entranceFee,
                provided: msg.value
            });
    }

    function pickWinner() public {}

    function getEntranceFee() public pure returns (uint256) {
        return i_entranceFee;
    }
}
