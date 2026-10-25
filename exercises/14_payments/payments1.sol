// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// payments1 — send vs transfer vs call
// Three ways to move ETH, and the interview answer:
//
//   send(x)     — forwards 2300 gas stipend, returns bool
//   transfer(x) — forwards 2300 gas stipend, reverts on failure
//   call{value:x}("") — forwards ALL gas (63/64 rule), returns bool
//
// send/transfer were "safe" because 2300 gas can't reenter — but that
// gas cap is now a LIABILITY: EIP-1884 raised sload cost, so a
// recipient whose fallback touches storage runs out of gas and your
// transfer bricks (the Istanbul 2019 "force-feeding" incident family).
// Best practice today: call + checks-effects-interactions + explicit
// return-value check.
//
// TODO: Implement `withdrawWithCall` — use .call, honor
// checks-effects-interactions, and revert "Transfer failed" when the
// call fails.

import "forge-std/Test.sol";

contract Payer {
    mapping(address => uint256) public owed;

    function credit(address to, uint256 amount) external {
        owed[to] += amount;
    }

    // Reverts if the recipient needs more than the 2300 stipend.
    function withdrawWithTransfer() external {
        uint256 amount = owed[msg.sender];
        owed[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // TODO: the modern path — .call, CEI, checked return value
    function withdrawWithCall() external {
    }

    receive() external payable {}
}

contract FancyWallet {
    // A perfectly reasonable wallet: logs the deposit in storage.
    uint256 public lastPayment;

    receive() external payable {
        lastPayment = msg.value; // ONE sload+sstore blows past 2300 gas
    }
}

contract Payments1Test is Test {
    Payer payer;
    FancyWallet wallet;

    function setUp() public {
        payer = new Payer();
        wallet = new FancyWallet();
        vm.deal(address(payer), 10 ether);
    }

    function testTransferBricksOnFancyWallet() public {
        payer.credit(address(wallet), 1 ether);
        vm.prank(address(wallet));
        vm.expectRevert(); // 2300 gas < one sstore — transfer reverts
        payer.withdrawWithTransfer();
    }

    function testCallSucceedsOnFancyWallet() public {
        payer.credit(address(wallet), 1 ether);

        vm.prank(address(wallet));
        payer.withdrawWithCall(); // must NOT revert

        assertEq(address(wallet).balance, 1 ether);
        assertEq(wallet.lastPayment(), 1 ether, "wallet ran its own logic");
        assertEq(payer.owed(address(wallet)), 0, "debt cleared");
    }
}
