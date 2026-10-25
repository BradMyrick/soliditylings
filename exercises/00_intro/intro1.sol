// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// intro1
// Welcome to soliditylings!
//
// Every exercise is a broken contract. Read the comments, open the file,
// fix the code, and the test beside it turns green.
//
// This first one is simple: the contract below is missing its closing
// brace. Solidity is block-scoped — every `{` needs its `}`. Make the
// file compile and the test passes.

import "forge-std/Test.sol";

contract Intro1 {
    // Nothing to do in here — just close the contract properly.
    uint256 public welcome;

contract Intro1Test is Test {
    function testWelcome() public {
        Intro1 intro = new Intro1();
        assertTrue(address(intro) != address(0));
    }
}
