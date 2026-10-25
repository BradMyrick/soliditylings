// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

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

    modifier onlyRole(bytes32 role) {
        require(hasRole[role][msg.sender], "missing role");
        _;
    }

    function grantRole(bytes32 role, address who) external onlyRole(role) {
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
        roles = new Roles();
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
        vm.expectRevert();
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
