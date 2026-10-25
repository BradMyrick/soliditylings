// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// escrow6 — the arbiter (mini-capstone of the section)
// A full mini-escrow in the classic three-party shape: buyer, seller,
// arbiter. The twist that makes it SAFE rather than 2016-vintage:
// PULL payments. Nobody is ever PUSHED ETH mid-transaction — the
// resolution only moves ACCOUNTING, and each party collects their own
// winnings. Push pays attackers; pull pays payees.
//
// TODO: Implement `resolve` — either outcome (release or refund)
// updates the escrow's withdrawable accounting and its state, and
// nothing else. Then implement `withdraw` for the winning party.
//
//   checks:    only arbiter, only Funded, only the two outcomes
//   effects:   set state, credit the winner's withdrawable
//   (no interactions here at all — that's the pattern)

import "forge-std/Test.sol";

contract ArbiterEscrow {
    enum Outcome {
        None,
        PaySeller,
        RefundBuyer
    }

    enum State {
        Funded,
        Resolved
    }

    address public buyer;
    address public seller;
    address public arbiter; // neutral third party — cannot be a party
    uint256 public amount;
    State public state;

    mapping(address => uint256) public withdrawable;

    error OnlyArbiter();
    error WrongState();
    error NothingToWithdraw();

    constructor(address _buyer, address _seller) payable {
        require(msg.value > 0, "empty");
        require(_buyer != _seller, "same party");
        buyer = _buyer;
        seller = _seller;
        arbiter = msg.sender; // deployer arbitrates (and cannot be a party)
        amount = msg.value;
        state = State.Funded;
    }

    // TODO: resolve — arbiter picks the winner; credit accounting ONLY
    function resolve(Outcome outcome) external {
    }

    // TODO: withdraw — a credited party pulls their ETH
    function withdraw() external {
    }

    receive() external payable {}
}

contract Escrow6Test is Test {
    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");

    function deploy() internal returns (ArbiterEscrow e) {
        vm.deal(address(this), 10 ether);
        // The TEST contract deploys (and thus arbitrates); the buyer is
        // merely the counterparty who can be made whole.
        e = new ArbiterEscrow{value: 1 ether}(buyer, seller);
    }

    function testResolvePaysSellerViaPull() public {
        ArbiterEscrow e = deploy();

        e.resolve(ArbiterEscrow.Outcome.PaySeller); // accounting only

        vm.prank(seller);
        e.withdraw(); // seller pulls

        assertEq(seller.balance, 1 ether);
        assertTrue(e.state() == ArbiterEscrow.State.Resolved);
    }

    function testResolveRefundsBuyerViaPull() public {
        ArbiterEscrow e = deploy();

        e.resolve(ArbiterEscrow.Outcome.RefundBuyer);

        vm.prank(buyer);
        e.withdraw();

        assertEq(buyer.balance, 1 ether, "buyer made whole");
        assertEq(seller.balance, 0);
    }

    function testOnlyArbiterResolves() public {
        ArbiterEscrow e = deploy();

        vm.prank(seller);
        vm.expectRevert(ArbiterEscrow.OnlyArbiter.selector);
        e.resolve(ArbiterEscrow.Outcome.PaySeller);
    }

    function testCannotResolveTwice() public {
        ArbiterEscrow e = deploy();
        e.resolve(ArbiterEscrow.Outcome.PaySeller);

        vm.expectRevert(ArbiterEscrow.WrongState.selector);
        e.resolve(ArbiterEscrow.Outcome.RefundBuyer); // no take-backs
    }
}
