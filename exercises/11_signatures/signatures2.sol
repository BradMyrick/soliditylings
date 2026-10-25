// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// signatures2
// You never sign "a message" — you sign a 32-byte digest of it. The
// standard tool is:
//
//   keccak256(abi.encode(a, b, ...))      // fixed-size args, padded — safe
//   keccak256(abi.encodePacked(a, b, ...)) // tight packing — careful!
//
// encodePacked is cheaper but DANGEROUS with two adjacent dynamic
// values: ("a","bc") and ("ab","c") pack to the same bytes. Rule for
// interviews: use abi.encode unless every argument is fixed-size.
//
// TODO: Implement `hashAction` — keccak256 over abi.encode of (who,
// amount, action) — and `safePacked` — keccak256 over the packed
// encoding of two uint128s (fixed-size, so packing is collision-free).

import "forge-std/Test.sol";

contract Hasher {
    // TODO: keccak of the ABI-encoded tuple (who, amount, action)
    function hashAction(address who, uint256 amount, string memory action)
        external
        pure
        returns (bytes32)
    {
        return bytes32(0); // REPLACE ME
    }

    // TODO: keccak of the tightly-packed pair (a, b) — both fixed-size
    function safePacked(uint128 a, uint128 b) external pure returns (bytes32) {
        return bytes32(0); // REPLACE ME
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
