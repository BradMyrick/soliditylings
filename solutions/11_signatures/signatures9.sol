// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract Verifier {
    error NotVerifier();
    error Expired();
    error AlreadyConsumed();

    address public immutable verifier;
    mapping(uint256 => bool) public consumed;

    constructor(address v) {
        verifier = v;
    }

    function digestFor(uint256 escrowId, address recipient, uint256 amount, uint256 deadline)
        public
        pure
        returns (bytes32)
    {
        bytes32 inner = keccak256(abi.encode("release", escrowId, recipient, amount, deadline));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", inner));
    }

    function split(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "bad length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function verify(uint256 escrowId, address recipient, uint256 amount, uint256 deadline, bytes memory sig)
        external
        returns (bool)
    {
        (uint8 v, bytes32 r, bytes32 s) = split(sig);

        if (consumed[escrowId]) revert AlreadyConsumed(); // replay guard
        if (block.timestamp > deadline) revert Expired(); // expiry guard
        if (ecrecover(digestFor(escrowId, recipient, amount, deadline), v, r, s) != verifier) {
            revert NotVerifier(); // signature + audience guard (digest binds them)
        }

        consumed[escrowId] = true; // consume before returning control
        return true;
    }
}

contract Signatures9Test is Test {
    Verifier verifier;
    uint256 constant VERIFIER_PK = 0xCE0;
    address verifierAddr;

    function setUp() public {
        verifierAddr = vm.addr(VERIFIER_PK);
        verifier = new Verifier(verifierAddr);
    }

    function sign(uint256 escrowId, address recipient, uint256 amount, uint256 deadline)
        internal
        view
        returns (bytes memory)
    {
        bytes32 digest = verifier.digestFor(escrowId, recipient, amount, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(VERIFIER_PK, digest);
        return abi.encodePacked(r, s, v);
    }

    function testHappyPath() public {
        bytes memory sig = sign(1, address(this), 1 ether, block.timestamp + 1 hours);
        assertTrue(verifier.verify(1, address(this), 1 ether, block.timestamp + 1 hours, sig));
    }

    function testWrongSignerRejected() public {
        bytes32 digest = verifier.digestFor(1, address(this), 1 ether, block.timestamp + 1 hours);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBA0BAD, digest);

        vm.expectRevert(Verifier.NotVerifier.selector);
        verifier.verify(1, address(this), 1 ether, block.timestamp + 1 hours, abi.encodePacked(r, s, v));
    }

    function testExpiredRejected() public {
        uint256 deadline = block.timestamp - 1;
        bytes memory sig = sign(1, address(this), 1 ether, deadline);

        vm.expectRevert(Verifier.Expired.selector);
        verifier.verify(1, address(this), 1 ether, deadline, sig);
    }

    function testReplayRejected() public {
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = sign(1, address(this), 1 ether, deadline);

        assertTrue(verifier.verify(1, address(this), 1 ether, deadline, sig));
        vm.expectRevert(Verifier.AlreadyConsumed.selector);
        verifier.verify(1, address(this), 1 ether, deadline, sig);
    }

    function testAudienceIsBound() public {
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = sign(1, address(0xA), 1 ether, deadline);

        vm.expectRevert(Verifier.NotVerifier.selector);
        verifier.verify(1, address(0xB), 1 ether, deadline, sig);
    }
}
