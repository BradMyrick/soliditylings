// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Errors1 {
    error Unauthorized(address caller);

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function doSomethingRestricted() public {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
    }
}

contract Errors1Test is Test {
    Errors1 target;

    function setUp() public {
        target = new Errors1();
    }

    function testOwnerSucceeds() public {
        target.doSomethingRestricted();
    }

    function testStrangerReverts() public {
        vm.prank(address(0xDEAD));
        vm.expectRevert();
        target.doSomethingRestricted();
    }
}
