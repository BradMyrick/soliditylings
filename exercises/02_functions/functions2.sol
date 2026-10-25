// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// functions2
// Visibility, from most to least open:
//
//   public    — anyone, plus internally
//   external  — anyone, but only from outside (cheaper for big args)
//   internal  — this contract and its children only
//   private   — this contract only
//
// Right now `increment` has no visibility at all, so it doesn't compile.
//
// TODO: Give `increment` a visibility that lets ANYONE call it.

import "forge-std/Test.sol";

contract Functions2 {
    uint256 public counter;

    // TODO: add a visibility keyword
    function increment() {
        counter += 1;
    }
}

contract Functions2Test is Test {
    Functions2 target;

    function setUp() public {
        target = new Functions2();
    }

    function testAnyoneCanCall() public {
        // A stranger calls through a low-level call — this only works
        // if `increment` is reachable from outside the contract.
        (bool success,) = address(target).call(abi.encodeWithSignature("increment()"));
        assertTrue(success, "increment() must be callable from outside");
        assertEq(target.counter(), 1);

        // And the contract itself can still use it internally.
        target.increment();
        assertEq(target.counter(), 2);
    }
}
