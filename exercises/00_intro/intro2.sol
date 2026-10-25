// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// intro2
// Tests are contracts too!
//
// soliditylings runs Foundry (forge) behind the scenes, so every exercise
// carries its own test contract — you fix the code until the test passes.
//
// This one fails an assertion: `returnTrue()` says `false`, but the test
// expects `true`. Flip it.

import "forge-std/Test.sol";

contract Intro2 {
    function returnTrue() public pure returns (bool) {
        return false; // TODO: make the test pass
    }
}

contract Intro2Test is Test {
    Intro2 public intro;

    function setUp() public {
        intro = new Intro2();
    }

    function testReturnTrue() public {
        assertTrue(intro.returnTrue(), "Should return true");
    }
}
