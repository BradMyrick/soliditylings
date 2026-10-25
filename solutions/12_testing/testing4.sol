// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract SigGate {
    address public immutable signer;

    constructor(address s) {
        signer = s;
    }

    function digestFor(address to, uint256 amount) public pure returns (bytes32) {
        bytes32 inner = keccak256(abi.encode("release", to, amount));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", inner));
    }

    function release(address to, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = digestFor(to, amount);
        require(ecrecover(digest, v, r, s) == signer, "bad sig");
        payable(to).transfer(amount);
    }

    receive() external payable {}
}

contract Testing4Test is Test {
    SigGate gate;
    uint256 constant SIGNER_PK = 0x51C6;

    function setUp() public {
        gate = new SigGate(vm.addr(SIGNER_PK));
        vm.deal(address(gate), 10 ether);
    }

    function testReleaseWithValidSig() public {
        address to = address(0xBEEF);
        uint256 amount = 1 ether;

        bytes32 digest = gate.digestFor(to, amount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PK, digest);

        gate.release(to, amount, v, r, s);
        assertEq(address(0xBEEF).balance, 1 ether, "signed release paid out");
    }

    function testBadSigRejected() public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBA0BAD, gate.digestFor(address(0xBEEF), 1 ether));
        vm.expectRevert();
        gate.release(address(0xBEEF), 1 ether, v, r, s);
    }
}
