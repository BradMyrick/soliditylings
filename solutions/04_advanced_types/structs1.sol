// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Structs1 {
    struct User {
        string username;
        uint256 score;
    }

    User public currentUser;

    function setUser(string memory _username, uint256 _score) public {
        currentUser = User(_username, _score);
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
