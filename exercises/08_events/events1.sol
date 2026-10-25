// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// events1
// Events are the contract's logging mechanism — written to the
// transaction receipt (not storage), readable by off-chain indexers,
// cheap. `indexed` marks up to three parameters as searchable filters.
//
//   event Ping(address indexed sender);
//   emit Ping(msg.sender);
//
// TODO: 1. Declare the `Ping` event with an indexed `address sender`.
//       2. Emit it from `doPing` with the caller's address.

import "forge-std/Test.sol";

contract Events1 {
    // TODO: declare the event here

    function doPing() public {
        // TODO: emit it
    }
}

contract Events1Test is Test {
    Events1 target;

    // The test mirrors the event so vm.expectEmit can match it.
    event Ping(address indexed sender);

    function setUp() public {
        target = new Events1();
    }

    function testPing() public {
        vm.expectEmit(true, false, false, false);
        emit Ping(address(this)); // what we expect to see...
        target.doPing();          // ...when this runs
    }
}
