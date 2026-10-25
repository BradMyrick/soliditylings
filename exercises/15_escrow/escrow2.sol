// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// escrow2 — many escrows, one contract
// One contract, many deals: the mapping-keyed pattern that every
// factory/marketplace/escrow system uses. A bytes32 id keeps escrows
// independent — deal A's release can never touch deal B — and the
// counter guarantees uniqueness.
//
//   struct Escrow { address buyer; address seller; uint256 amount; State state; }
//   mapping(bytes32 => Escrow) public escrows;
//
// TODO: Implement `create` — record a NEW escrow under a fresh id,
// pull the buyer's ETH in, and emit EscrowCreated. Return the id.

import "forge-std/Test.sol";

contract EscrowBook {
    struct Escrow {
        address buyer;
        address seller;
        uint256 amount;
        bool funded;
    }

    mapping(bytes32 => Escrow) public escrows;
    uint256 public count;

    event EscrowCreated(bytes32 indexed id, address indexed buyer, address indexed seller, uint256 amount);

    error AlreadyFunded();

    function nextId() internal returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this), count++));
    }

    // TODO: create + fund a new escrow (buyer is msg.sender, value is msg.value)
    function create(address seller) external payable returns (bytes32 id) {
        return bytes32(0); // REPLACE ME
    }
}

contract Escrow2Test is Test {
    EscrowBook book;
    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");

    function setUp() public {
        book = new EscrowBook();
        vm.deal(buyer, 10 ether);
    }

    function testCreateRecordsDeal() public {
        vm.prank(buyer);
        bytes32 id = book.create{value: 1 ether}(seller);

        (address b, address s, uint256 amount, bool funded) = book.escrows(id);
        assertEq(b, buyer);
        assertEq(s, seller);
        assertEq(amount, 1 ether);
        assertTrue(funded);
        assertEq(address(book).balance, 1 ether);
    }

    function testEscrowsAreIndependent() public {
        vm.startPrank(buyer);
        bytes32 a = book.create{value: 1 ether}(seller);
        bytes32 b = book.create{value: 2 ether}(seller);
        vm.stopPrank();

        (, , uint256 amtA, ) = book.escrows(a);
        (, , uint256 amtB, ) = book.escrows(b);
        assertFalse(a == b, "ids must be unique");
        assertEq(amtA, 1 ether);
        assertEq(amtB, 2 ether);
        assertEq(book.count(), 2);
    }
}
