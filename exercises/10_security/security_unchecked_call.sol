// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// security_unchecked_call — AUDIT FINDING: "unchecked low-level call"
// `call` returns a bool and SWALLOWS the failure when you ignore it.
// A payout that "succeeded" while silently failing is a fund-loss
// finding: the state says paid, the recipient got nothing (or the
// opposite — state rolled forward, money stayed).
//
// TODO: Check the return value of the `call` in `withdraw` and revert
// with "Transfer failed" when it is false. The Rejector contract in
// the test refuses ETH; your withdrawal to it must fail LOUDLY.

import "forge-std/Test.sol";

contract Faucet {
    mapping(address => uint256) public owed;

    function credit(address to, uint256 amount) external {
        owed[to] += amount;
    }

    function withdraw() external {
        uint256 amount = owed[msg.sender];
        owed[msg.sender] = 0;
        (bool sent,) = msg.sender.call{value: amount}(""); // UNCHECKED
        // TODO: revert with "Transfer failed" when !sent
    }

    receive() external payable {}
}

contract Rejector {
    // Deliberately refuses ETH: no receive/fallback, and this function
    // burns gas on purpose so nothing can sneak value in.
    function burn() external pure returns (uint256) {
        uint256 x;
        for (uint256 i = 0; i < 1000; i++) {
            x += i;
        }
        return x;
    }
}

contract UncheckedCallTest is Test {
    Faucet faucet;
    Rejector rejector;

    function setUp() public {
        faucet = new Faucet();
        vm.deal(address(faucet), 10 ether);
        rejector = new Rejector();
    }

    function testWithdrawToRejectorReverts() public {
        faucet.credit(address(rejector), 1 ether);
        // The Rejector can't receive ETH — the withdraw must revert,
        // not silently "succeed" while keeping the money.
        vm.prank(address(rejector));
        vm.expectRevert();
        faucet.withdraw();
    }

    function testWithdrawToReceiverWorks() public {
        faucet.credit(address(this), 1 ether);
        faucet.withdraw();
        assertEq(faucet.owed(address(this)), 0, "debt cleared");
    }

    receive() external payable {}
}
