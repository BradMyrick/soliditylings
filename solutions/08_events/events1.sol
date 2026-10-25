// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Events1 {
    event Ping(address indexed sender);

    function doPing() public {
        emit Ping(msg.sender);
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
