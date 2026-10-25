// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// ownership4 — bounded administration ("sweep safely")
// The Saifuro requirement, verbatim: "no path in which Saifuro can
// move a counterparty's money." Escrows still need an operational
// sweep (rounding dust, misplaced transfers) — the audited shape is a
// sweep that mathematically CANNOT exceed the protocol's own excess:
//
//   excess = contract balance − sum(user deposits)
//
// The broken version below sweeps the whole balance — users' money
// included. Your fix: never let the sweep cross `totalDeposits`.
//
// TODO: Rewrite `sweep` so it can only take funds above
// `totalDeposits`. Keep the dust useful: sweeping the excess must
// work when there IS excess.

import "forge-std/Test.sol";

contract Sweepable {
    address public owner;
    uint256 public totalDeposits; // what users are owed, in aggregate

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function depositFor(address user) external payable {
        require(msg.value > 0, "empty");
        // (per-user bookkeeping omitted — aggregate is what matters here)
        totalDeposits += msg.value;
    }

    // BROKEN: takes everything, including user money
    function sweep(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    receive() external payable {}
}

contract Ownership4Test is Test {
    Sweepable vault;
    address ops = address(0x0F5);

    function setUp() public {
        vault = new Sweepable(); // test contract = owner
        vm.deal(ops, 0);
    }

    function testUsersMoneyIsUntouchable() public {
        vault.depositFor{value: 5 ether}(address(0xA));

        vm.expectRevert(); // no excess exists — sweep must refuse
        vault.sweep(ops);

        assertEq(address(vault).balance, 5 ether, "not a wei moves");
    }

    function testExcessIsSweepable() public {
        vault.depositFor{value: 5 ether}(address(0xA));

        // A kind stranger (or rounding dust) sends the vault extra ETH
        // that no user has a claim on.
        vm.deal(address(this), 3 ether);
        (bool ok,) = address(vault).call{value: 3 ether}("");
        assertTrue(ok);

        vault.sweep(ops); // sweeps exactly the excess

        assertEq(address(ops).balance, 3 ether, "ops gets the excess");
        assertEq(address(vault).balance, 5 ether, "user deposits remain");
    }

    function testStrangerCannotSweep() public {
        vm.prank(address(0xBA0BAD));
        vm.expectRevert(); // onlyOwner
        vault.sweep(address(0xBA0BAD));
    }
}
