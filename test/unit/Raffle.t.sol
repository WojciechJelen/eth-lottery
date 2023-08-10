// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gaslane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (
            entranceFee,
            interval,
            vrfCoordinator,
            gaslane,
            subscriptionId,
            callbackGasLimit
        ) = helperConfig.activeConfig();
    }

    function testRaffleInitializesInTheOpenState() public view {
        console.log("#####raffle state: %s", uint256(raffle.getRaffleState()));
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}
