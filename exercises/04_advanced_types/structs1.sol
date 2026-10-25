// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// structs1
// A struct groups related fields under one type:
//
//   struct User { string username; uint256 score; }
//
// Structs can live in storage (state), memory (locals), or calldata —
// and you construct one positionally: `User("alice", 10)` — or by name:
// `User({username: "alice", score: 10})`.
//
// TODO: 1. Define a struct named `User` with `string username` and
//          `uint256 score`.
//       2. In `setUser`, assign `currentUser` from the arguments.

import "forge-std/Test.sol";

contract Structs1 {
    // TODO: define the `User` struct here

    User public currentUser;

    function setUser(string memory _username, uint256 _score) public {
        // TODO: initialize `currentUser`
    }
}

contract Structs1Test is Test {
    Structs1 target;

    function setUp() public {
        target = new Structs1();
    }

    function testSetUser() public {
        target.setUser("alice", 10);
        (string memory username, uint256 score) = target.currentUser();
        assertEq(username, "alice");
        assertEq(score, 10);
    }
}
