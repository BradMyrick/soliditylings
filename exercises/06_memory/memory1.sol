// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// memory1
// Data location. Reference types (arrays, structs, strings, mappings)
// must say WHERE they live:
//
//   storage    — contract state, persistent, expensive
//   memory     — a fresh temporary copy, dies with the call
//   calldata   — read-only slice of the transaction input, cheapest
//
// The compiler refuses to guess. `string greeting` below has no home.
//
// TODO: Give `greeting` a data location. It only needs to exist for
// the duration of this call, and we don't mutate it — but `memory`
// is the conventional first answer for internal functions.

import "forge-std/Test.sol";

contract Memory1 {
    // TODO: add a data location to the parameter
    function sayHello(string greeting) public pure returns (string memory) {
        return greeting;
    }
}

contract Memory1Test is Test {
    Memory1 target;

    function setUp() public {
        target = new Memory1();
    }

    function testSayHello() public {
        assertEq(target.sayHello("hi"), "hi");
    }
}
