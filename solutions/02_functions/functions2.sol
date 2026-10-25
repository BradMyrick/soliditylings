// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Functions2 {
    uint256 public counter;

    function increment() public {
        counter += 1;
    }
}

contract Functions2Test is Test {
    Functions2 target;

    function setUp() public {
        target = new Functions2();
    }

    function testAnyoneCanCall() public {
        (bool success,) = address(target).call(abi.encodeWithSignature("increment()"));
        assertTrue(success, "increment() must be callable from outside");
        assertEq(target.counter(), 1);

        target.increment();
        assertEq(target.counter(), 2);
    }
}
