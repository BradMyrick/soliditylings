// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Hasher {
    function hashAction(address who, uint256 amount, string memory action)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(who, amount, action));
    }

    function safePacked(uint128 a, uint128 b) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }
}

contract Signatures2Test is Test {
    Hasher target;

    function setUp() public {
        target = new Hasher();
    }

    function testHashAction() public {
        bytes32 expected = keccak256(abi.encode(address(1), 2, "release"));
        assertEq(target.hashAction(address(1), 2, "release"), expected);
    }

    function testSafePacked() public {
        bytes32 expected = keccak256(abi.encodePacked(uint128(1), uint128(2)));
        assertEq(target.safePacked(1, 2), expected);
    }
}
