// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Calldata1 {
    function _hash(bytes calldata input) internal pure returns (bytes32) {
        return keccak256(input);
    }

    function processInput(bytes calldata input) external pure returns (bytes32) {
        return _hash(input);
    }
}

contract Calldata1Test is Test {
    Calldata1 target;

    function setUp() public {
        target = new Calldata1();
    }

    function testProcessInput() public {
        bytes memory data = bytes("hello");
        assertEq(target.processInput(data), keccak256(data));
    }
}
