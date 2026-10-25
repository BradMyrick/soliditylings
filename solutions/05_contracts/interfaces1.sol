// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

interface IGreeter {
    function greet() external pure returns (string memory);
}

contract Greeter is IGreeter {
    function greet() external pure returns (string memory) {
        return "Hello!";
    }
}

contract Caller {
    function callGreet(address target) external view returns (string memory) {
        return IGreeter(target).greet();
    }
}

contract Interfaces1Test is Test {
    Caller caller;
    Greeter greeter;

    function setUp() public {
        caller = new Caller();
        greeter = new Greeter();
    }

    function testCallThroughInterface() public {
        assertEq(caller.callGreet(address(greeter)), "Hello!");
    }
}
