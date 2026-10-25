// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// signatures5 — EIP-712 part 2: hashStruct + the full digest
// A typed message hashes its fields structurally:
//
//   TYPEHASH   = keccak256("Verdict(uint256 escrowId,address recipient,uint256 amount)")
//   hashStruct = keccak256(abi.encode(TYPEHASH, escrowId, recipient, amount))
//
// and the final digest stitches domain + message under the EIP-712
// header:
//
//   digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashStruct))
//
// That digest is what the signer signed, so it's also what the
// contract must feed to ecrecover.
//
// TODO: Implement `hashVerdict` and `digest`. (The domain separator
// is provided; compose it exactly as above.)

import "forge-std/Test.sol";

contract VerdictDigest {
    bytes32 public constant VERDICT_TYPEHASH =
        keccak256("Verdict(uint256 escrowId,address recipient,uint256 amount)");

    // TODO: hash the Verdict struct's fields with its typehash
    function hashVerdict(uint256 escrowId, address recipient, uint256 amount)
        external
        pure
        returns (bytes32)
    {
        return bytes32(0); // REPLACE ME
    }

    // TODO: "\x19\x01" ++ domainSeparator ++ hashStruct, hashed
    function digest(bytes32 domainSeparator, uint256 escrowId, address recipient, uint256 amount)
        external
        pure
        returns (bytes32)
    {
        return bytes32(0); // REPLACE ME
    }
}

contract Signatures5Test is Test {
    VerdictDigest target;
    uint256 constant PK = 0xA11CE;

    function setUp() public {
        target = new VerdictDigest();
    }

    function testHashVerdict() public {
        bytes32 expected = keccak256(
            abi.encode(target.VERDICT_TYPEHASH(), uint256(7), address(0xBEEF), 1 ether)
        );
        assertEq(target.hashVerdict(7, address(0xBEEF), 1 ether), expected);
    }

    function testDigestRoundTripsToSigner() public {
        bytes32 domain = keccak256("domain");
        bytes32 d = target.digest(domain, 7, address(0xBEEF), 1 ether);

        // The signer signs the digest; ecrecover over the SAME digest
        // must return the signer — that's the whole verification game.
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, d);
        assertEq(ecrecover(d, v, r, s), vm.addr(PK));
    }
}
