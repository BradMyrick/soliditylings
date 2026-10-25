// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Recover {
    function recover(bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        external
        pure
        returns (address)
    {
        return ecrecover(digest, v, r, s);
    }
}

contract Signatures1Test is Test {
    Recover target;

    uint256 constant PK = 0xA11CE;
    address public signer;

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
