// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Raffle.sol";

contract CounterTest is Test {
    Raffle public raffle;

    function setUp() public {
        raffle = new Raffle();
    }
}
