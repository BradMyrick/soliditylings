// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

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

    function nextId() internal returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this), count++));
    }

    function create(address seller) external payable returns (bytes32 id) {
        require(msg.value > 0, "empty");
        id = nextId();
        escrows[id] = Escrow(msg.sender, seller, msg.value, true);
        emit EscrowCreated(id, msg.sender, seller, msg.value);
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
