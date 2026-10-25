// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// arrays1
// A dynamic array is declared `T[]` and lives in storage, where it can
// grow. `.push(x)` appends; `.pop()` removes the last element; `.length`
// reads the size. Declaring it `public` gives you a free getter that
// takes an index.
//
// TODO: 1. Declare a public dynamic uint256 array named `numbers`.
//       2. In `addNumber`, append the argument to it.

import "forge-std/Test.sol";

contract Arrays1 {
    // TODO: declare `numbers` here

    function addNumber(uint256 number) public {
        // TODO: append `number`
    }

    // Reading `.length` from OUTSIDE is impossible on a public array —
    // the auto-getter only serves `numbers(index)`. Internally, it's fine.
    function count() public view returns (uint256) {
        return numbers.length;
    }
}

contract Arrays1Test is Test {
    Arrays1 target;

    function setUp() public {
        target = new Arrays1();
    }

    function testPush() public {
        target.addNumber(7);
        target.addNumber(42);
        assertEq(target.numbers(0), 7, "first element");
        assertEq(target.numbers(1), 42, "second element");
        assertEq(target.count(), 2, "length after two pushes");
    }
}
