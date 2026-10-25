// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// signatures3 — EIP-191 personal_sign
// Wallets signing a RAW string apply the personal_sign prefix so a
// data blob can't be confused with a transaction:
//
//   "\x19Ethereum Signed Message:\n32" ++ digest
//
// The \x19 byte dates to 2016: it makes the signed data an invalid
// RLP transaction, so a signature over a message can never be replayed
// AS a transaction. When your contract verifies a wallet-produced
// signature, it must hash the prefix exactly like the wallet did.
//
// TODO: Implement `prefixed` — keccak256 over the EIP-191 prefix
// bytes concatenated with the inner digest. The test signs the way
// MetaMask does; your digest must match.

import "forge-std/Test.sol";

contract PersonalSign {
    // TODO: hash(prefix_bytes ++ inner) — exactly what wallets sign.
    // (No constant for the prefix: it must be packed as RAW BYTES,
    // not pre-hashed — pack it inline with abi.encodePacked.)
    function prefixed(bytes32 inner) external pure returns (bytes32) {
        return bytes32(0); // REPLACE ME
    }
}

contract Signatures3Test is Test {
    PersonalSign target;
    uint256 constant PK = 0xA11CE;

    function setUp() public {
        target = new PersonalSign();
    }

    function testPrefixMatchesWallet() public {
        bytes32 inner = keccak256(abi.encode("hello", 42));
        bytes32 digest = target.prefixed(inner);

        // Sign the way a wallet does — over the PREFIXED digest.
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, digest);
        address recovered = ecrecover(digest, v, r, s);

        assertEq(recovered, vm.addr(PK), "prefixed digest must be the wallet's digest");
        assertEq(digest, keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", inner)));
    }
}
