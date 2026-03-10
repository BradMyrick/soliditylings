// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

// receive1.sol
// Make me pass!

contract Receive1 {
    uint256 public counter;

    // TODO: We want to accept plain ETH transfers (e.g. `address(target).transfer(1 ether)`)
    // AND we want to increment the counter when this happens.
    // What special function is used for this?
}

contract Receive1Test is Test {
    Receive1 target;

    function setUp() public {
        target = new Receive1();
    }

    function testReceive() public {
        // Keep in mind a direct transfer without data hits the `receive` function (or fallback).
        vm.deal(address(this), 1 ether);
        (bool success, ) = address(target).call{value: 1 ether}("");
        assertTrue(success, "The contract should accept plain ETH");
        assertEq(address(target).balance, 1 ether);
        assertEq(target.counter(), 1);
    }
}
