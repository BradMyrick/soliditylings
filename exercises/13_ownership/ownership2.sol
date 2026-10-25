// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// ownership2 — two-step ownership transfer
// `transferOwnership(newOwner)` in ONE step has a failure mode every
// auditor knows: send it to a mistyped or dead address and the contract
// is ownerless forever — bricked admin plane (this literally froze
// millions in Vyper settings contracts). The two-step pattern makes
// the mistake recoverable:
//
//   1. current owner  → propose(newOwner)   (reversible)
//   2. NEW owner      → claimOwnership()    (accepts or ignores)
//
// If the new owner is wrong, it simply never claims; the real owner
// proposes someone else.
//
// TODO: Implement `claimOwnership` — only the pending owner may claim,
// and claiming must atomically install them AND clear the proposal.

import "forge-std/Test.sol";

contract TwoStepOwnable {
    address public owner;
    address public pendingOwner;

    event OwnershipProposed(address indexed candidate);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function proposeOwnership(address candidate) external onlyOwner {
        pendingOwner = candidate;
        emit OwnershipProposed(candidate);
    }

    // TODO: claim — only pendingOwner; installs and clears the proposal
    function claimOwnership() external {
    }
}

contract Ownership2Test is Test {
    TwoStepOwnable ownable;
    address successor = makeAddr("successor");

    function setUp() public {
        ownable = new TwoStepOwnable(); // test contract = owner
    }

    function testClaimInstallsOwner() public {
        ownable.proposeOwnership(successor);

        vm.prank(successor);
        ownable.claimOwnership();

        assertEq(ownable.owner(), successor, "successor must be installed");
        assertEq(ownable.pendingOwner(), address(0), "proposal must be cleared");
    }

    function testStrangerCannotClaim() public {
        ownable.proposeOwnership(successor);

        vm.prank(address(0xBA0BAD));
        vm.expectRevert(); // not the pending owner
        ownable.claimOwnership();

        assertEq(ownable.owner(), address(this), "owner unchanged");
    }

    function testWrongAddressProposalIsRecoverable() public {
        ownable.proposeOwnership(address(0xDEAD)); // the typo
        ownable.proposeOwnership(successor); // recover: re-propose

        vm.prank(successor);
        ownable.claimOwnership();
        assertEq(ownable.owner(), successor);
    }
}
