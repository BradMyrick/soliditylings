// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract VerdictDigest {
    bytes32 public constant VERDICT_TYPEHASH =
        keccak256("Verdict(uint256 escrowId,address recipient,uint256 amount)");

    function hashVerdict(uint256 escrowId, address recipient, uint256 amount)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(VERDICT_TYPEHASH, escrowId, recipient, amount));
    }

    function digest(bytes32 domainSeparator, uint256 escrowId, address recipient, uint256 amount)
        external
        pure
        returns (bytes32)
    {
        bytes32 structHash = keccak256(
            abi.encode(VERDICT_TYPEHASH, escrowId, recipient, amount)
        );
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PK, d);
        assertEq(ecrecover(d, v, r, s), vm.addr(PK));
    }
}
