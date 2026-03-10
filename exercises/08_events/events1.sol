// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

// events1.sol
// Make me pass!

contract Events1 {
    // TODO: Define an event `Ping` with a single argument `address indexed sender`.

    function doPing() public {
        // TODO: Emit the `Ping` event with `msg.sender`.
    }
}

contract Events1Test is Test {
    Events1 target;

    event Ping(address indexed sender);

    function setUp() public {
        target = new Events1();
    }

    function testPing() public {
        vm.expectEmit(true, false, false, false);
        emit Ping(address(this));
        
        target.doPing();
    }
}
