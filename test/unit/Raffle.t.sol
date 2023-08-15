// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";

contract RaffleTest is Test {
    /**
     * @notice we need to redefine the events here
     */
    event EnteredRaffle(address indexed participant);

    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gaslane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

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
            callbackGasLimit,
            link
        ) = helperConfig.activeConfig();

        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInTheOpenState() public view {
        console.log("raffle state: %s", uint256(raffle.getRaffleState()));
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsIfYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthToEnterRaffle.selector);
        raffle.enterRaflle();
    }

    function testRaffleRecordsPlayersWhenTheyEntered() public {
        vm.prank(PLAYER);
        raffle.enterRaflle{value: STARTING_USER_BALANCE}();
        assert(raffle.getParticipants().length == 1);
    }

    function testEmitsEventWhenPlayerEnters() public {
        vm.prank(PLAYER);

        // last parameter is a address of the emitter
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);

        raffle.enterRaflle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaflle{value: entranceFee}();
        // sets enough time passed, so we are sure that Rafle is in calculating state
        vm.warp(block.timestamp + interval + 1);
        // increasing the block number, we don't have to do this
        vm.roll(block.number + 1);
        raffle.performUpkeep("0x0");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaflle{value: entranceFee}();
    }

    function testCheckUpkeepReturnFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("0x0");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnFalseIfIRaffleIsNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaflle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("0x0");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("0x0");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnFalseIfEnoughTimeDoesNotPass() public {
        vm.prank(PLAYER);
        raffle.enterRaflle{value: entranceFee}();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("0x0");

        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueIfParametersAreGood() public {
        vm.prank(PLAYER);
        raffle.enterRaflle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("0x0");

        assert(upkeepNeeded);
    }
}
