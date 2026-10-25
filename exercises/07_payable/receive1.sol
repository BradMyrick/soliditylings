// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// receive1
// Two special functions catch plain ETH transfers (calls with empty
// calldata):
//
//   receive() external payable {}  — called on transfers with NO data
//   fallback() external payable {} — called when nothing else matches
//
// A contract without either REJECTS plain transfers. `receive` is the
// one you want for "this contract can be paid."
//
// TODO: Add the special function that accepts empty-calldata ETH
// transfers, and increment `counter` inside it so we can observe it.

import "forge-std/Test.sol";

contract Receive1 {
    uint256 public counter;

    // TODO: accept plain ETH transfers and count them
}

contract Receive1Test is Test {
    Receive1 target;

    function setUp() public {
        target = new Receive1();
    }

    function testReceive() public {
        (bool success,) = address(target).call{value: 1 ether}("");
        assertTrue(success, "The contract should accept plain ETH");
        assertEq(address(target).balance, 1 ether);
        assertEq(target.counter(), 1, "receive should have run once");
    }
}
