// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// ownership1 — the pause switch
// "Audits and releases: ... with deployment scripts, a pause switch
// and a recovery runbook alongside." The pause is the circuit breaker
// every release ships with — a modifier pair:
//
//   whenNotPaused  — guards the actions you want to freeze
//   onlyOwner      — guards pause()/unpause() themselves
//
// Note the pause is DENIAL, not THEFT: pausing blocks actions, it
// never redirects funds.
//
// TODO: 1. Write the `whenNotPaused` modifier (revert "paused").
//       2. Apply it to `deposit`.
//       3. Give pause/unpause owner-only access.

import "forge-std/Test.sol";

contract PausableVault {
    bool public paused;
    address public owner;

    event Paused();
    event Unpaused();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // TODO: whenNotPaused modifier


    // TODO: apply the pause guard
    function deposit() external payable {
        // funds accepted
    }

    // TODO: owner-only pause
    function pause() external {
        paused = true;
        emit Paused();
    }

    // TODO: owner-only unpause
    function unpause() external {
        paused = false;
        emit Unpaused();
    }

    receive() external payable {}
}

contract Ownership1Test is Test {
    PausableVault vault;

    function setUp() public {
        vault = new PausableVault();
    }

    function testDepositBlockedWhilePaused() public {
        vault.pause();
        vm.expectRevert(); // whenNotPaused fires
        vault.deposit{value: 1 ether}();

        vault.unpause();
        vault.deposit{value: 1 ether}(); // works again
        assertEq(address(vault).balance, 1 ether);
    }

    function testOnlyOwnerCanPause() public {
        vm.prank(address(0xBA0BAD));
        vm.expectRevert(); // onlyOwner fires
        vault.pause();
        assertFalse(vault.paused(), "stranger must not pause");
    }

    function testOnlyOwnerCanUnpause() public {
        vault.pause();
        vm.prank(address(0xBA0BAD));
        vm.expectRevert();
        vault.unpause();
        assertTrue(vault.paused());
    }
}
