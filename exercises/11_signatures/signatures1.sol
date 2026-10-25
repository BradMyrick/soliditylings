// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// signatures1
// Ethereum signed messages rest on ONE precompile: `ecrecover`.
// Give it a 32-byte digest plus the signature's (v, r, s) and it
// returns the address whose private key produced that signature —
// or address(0) if the inputs don't form a valid signature.
//
//   address signer = ecrecover(digest, v, r, s);
//
// Verification is then a one-line comparison: does the recovered
// address match who was supposed to sign?
//
// TODO: Complete `recover` using the ecrecover precompile.

import "forge-std/Test.sol";

contract Recover {
    // TODO: return the address recovered from (digest, v, r, s)
    function recover(bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        external
        pure
        returns (address)
    {
        return address(0); // REPLACE ME
    }
}

contract Signatures1Test is Test {
    Recover target;

    // Any private key works in tests — this one is a throwaway.
    uint256 constant PK = 0xA11CE;
    address public signer; // derived from PK

    function setUp() public {
        target = new Recover();
        signer = vm.addr(PK);
    }

    function testRecoversSigner() public {
        bytes32 digest = keccak256("signatures1");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, digest);

        assertEq(target.recover(digest, v, r, s), signer, "must recover the key's address");
    }

    function testGarbageReturnsZero() public {
        // v=0 is not a valid recovery id — ecrecover returns
        // address(0) rather than reverting. (Careful: v=27 with junk
        // r/s still recovers SOME address — junk alone isn't invalid!)
        address got = target.recover(bytes32(0), 0, bytes32(uint256(1)), bytes32(uint256(2)));
        assertEq(got, address(0), "invalid v recovers address(0)");
    }
}
