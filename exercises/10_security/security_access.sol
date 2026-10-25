// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// security_access — AUDIT FINDING: "unprotected privileged function"
// The most common critical in audits isn't clever — it's a function
// that should have had a guard and doesn't. Parity 2017: one
// unprotected `kill` froze 513,740 ETH forever. Default-deny: every
// state-changing external function PROVES who may call it.
//
// TODO: `setTreasury` is meant to be owner-only, and `deposit` is
// meant to be open to everyone. Only one of them has it backwards.
// Fix the access control so the tests pass.

import "forge-std/Test.sol";

contract TipJar {
    address public owner;
    address public treasury;

    constructor() {
        owner = msg.sender;
        treasury = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // Meant to be open to everyone — tips are tips.
    function deposit() external payable onlyOwner {
        // (funds accepted)
    }

    // Meant to be owner-only — where the money goes.
    function setTreasury(address t) external {
        treasury = t;
    }

    receive() external payable {}
}

contract AccessTest is Test {
    TipJar jar;

    function setUp() public {
        jar = new TipJar();
    }

    function testAnyoneCanDeposit() public {
        vm.deal(address(0xBEEF), 1 ether);
        vm.prank(address(0xBEEF));
        jar.deposit{value: 1 ether}();
        assertEq(address(jar).balance, 1 ether);
    }

    function testOnlyOwnerSetsTreasury() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(); // strangers must be locked out
        jar.setTreasury(address(0xBEEF));

        jar.setTreasury(address(0x1234)); // owner is fine
        assertEq(jar.treasury(), address(0x1234));
    }
}
