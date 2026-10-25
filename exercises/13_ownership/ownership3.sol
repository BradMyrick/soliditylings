// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// ownership3 — role separation
// One owner doing everything is a single point of failure AND a single
// point of compromise. Real systems split powers into roles so a leak
// of one key can't do everything: the PAUSER key (hot, can halt) is
// different from the VERIFIER key (cold, signs verdicts), and NEITHER
// can touch funds.
//
//   keccak256("PAUSER_ROLE"), keccak256("VERIFIER_ROLE")
//
// (OpenZeppelin's AccessControl is exactly this — you're building the
// 20-line core so the interview answer is muscle memory.)
//
// TODO: 1. Write the `onlyRole(bytes32)` modifier.
//       2. Wire `grantRole` so only an existing holder of a role (or
//          the deployer via constructor grants) can grant it.

import "forge-std/Test.sol";

contract Roles {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    mapping(bytes32 => mapping(address => bool)) public hasRole;
    bool public paused;

    constructor() {
        hasRole[PAUSER_ROLE][msg.sender] = true;
        hasRole[VERIFIER_ROLE][msg.sender] = true;
    }

    // TODO: onlyRole modifier — revert "missing role" when the caller
    // lacks the given role.


    // TODO: grant — restricted so only a holder of `role` (or the
    // role's own members) can mint more of it
    function grantRole(bytes32 role, address who) external {
        hasRole[role][who] = true;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        paused = true;
    }
}

contract Ownership3Test is Test {
    Roles roles;
    address pauser = address(0xA0);

    function setUp() public {
        roles = new Roles(); // test contract holds both roles
    }

    function testPauserCanPause() public {
        roles.grantRole(roles.PAUSER_ROLE(), pauser);
        vm.prank(pauser);
        roles.pause();
        assertTrue(roles.paused());
    }

    function testVerifierCannotPause() public {
        address verifier = address(0xB0);
        roles.grantRole(roles.VERIFIER_ROLE(), verifier);

        vm.prank(verifier);
        vm.expectRevert(); // VERIFIER_ROLE != PAUSER_ROLE
        roles.pause();
    }

    function testStrangerCannotGrantRoles() public {
        // Read the role FIRST: a getter between prank/expectRevert and
        // the target call would consume them (classic forge gotcha).
        bytes32 pauserRole = roles.PAUSER_ROLE();

        vm.prank(address(0xBA0BAD));
        vm.expectRevert(); // role holders only
        roles.grantRole(pauserRole, address(0xBA0BAD));
    }
}
