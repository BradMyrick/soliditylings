// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract ReleaseEscrow {
    enum State {
        Empty,
        Funded,
        Released
    }

    struct Escrow {
        address buyer;
        address seller;
        uint256 amount;
        State state;
    }

    mapping(bytes32 => Escrow) public escrows;

    error WrongState();

    function fund(bytes32 id, address buyer, address seller) external payable {
        escrows[id] = Escrow(buyer, seller, msg.value, State.Funded);
    }

    function release(bytes32 id) external {
        Escrow storage e = escrows[id];
        if (e.state != State.Funded) revert WrongState();

        e.state = State.Released; // FIXED: effect BEFORE interaction
        payable(e.seller).transfer(e.amount);
    }

    receive() external payable {}
}

contract ReentrantSeller {
    ReleaseEscrow public escrow;
    bytes32 public target;

    constructor(ReleaseEscrow e) {
        escrow = e;
    }

    function setTarget(bytes32 id) external {
        target = id;
    }

    function release(bytes32 id) external {
        escrow.release(id);
    }

    receive() external payable {
        if (target != bytes32(0)) {
            escrow.release(target);
        }
    }
}

contract Escrow3Test is Test {
    ReleaseEscrow escrow;
    ReentrantSeller evilSeller;
    address seller = makeAddr("seller");

    function setUp() public {
        escrow = new ReleaseEscrow();
        evilSeller = new ReentrantSeller(escrow);
        vm.deal(address(this), 10 ether);

        escrow.fund{value: 5 ether}(bytes32("E1"), address(this), address(evilSeller));
        evilSeller.setTarget(bytes32("E1"));
    }

    function testReentrantReleaseReverts() public {
        vm.expectRevert();
        evilSeller.release(bytes32("E1"));

        assertEq(address(escrow).balance, 5 ether, "not a wei moved");
    }

    function testHonestReleaseWorks() public {
        escrow.fund{value: 1 ether}(bytes32("E2"), address(this), seller);
        escrow.release(bytes32("E2"));
        assertEq(seller.balance, 1 ether);
        assertEq(address(escrow).balance, 5 ether, "E1 untouched");
    }
}
