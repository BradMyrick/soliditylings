// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract PersonalSign {
    function prefixed(bytes32 inner) external pure returns (bytes32) {
        // The prefix is packed as RAW BYTES — never pre-hashed.
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", inner));
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

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, digest);
        address recovered = ecrecover(digest, v, r, s);

        assertEq(recovered, vm.addr(PK), "prefixed digest must be the wallet's digest");
        assertEq(digest, keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", inner)));
    }
}
