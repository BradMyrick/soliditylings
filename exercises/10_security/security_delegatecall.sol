// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// security_delegatecall — AUDIT FINDING: "storage collision via delegatecall"
// `delegatecall` executes another contract's code against YOUR storage
// — same msg.sender, same msg.value, but the callee's storage layout
// is copied over yours slot by slot. If the layouts don't match
// EXACTLY, the callee writes its slot 0 into whatever YOU keep in
// slot 0.
//
// Below, the library writes to its slot 0 (`num`) — but in Storage the
// slot 0 belongs to `owner`. Calling setNum clobbers the owner.
// (This exact bug pattern bricked Parity's multi-sig in 2017.)
//
// TODO: Fix the storage layout so the delegated write lands on `num`
// and `owner` is never clobbered. Think declaration order = slot order.

import "forge-std/Test.sol";

contract NumberLibrary {
    // slot 0 in the library
    uint256 public num;

    function setNum(uint256 v) external {
        num = v;
    }
}

contract Storage {
    address public owner; // slot 0 — COLLIDES with library's num
    uint256 public num; // slot 1
    NumberLibrary public lib; // slot 2

    constructor() {
        owner = msg.sender;
        lib = new NumberLibrary();
    }

    function setNum(uint256 v) external {
        address(lib).delegatecall(abi.encodeWithSelector(NumberLibrary.setNum.selector, v));
    }
}

contract DelegatecallTest is Test {
    Storage store;

    function setUp() public {
        store = new Storage();
    }

    function testOwnerNotClobbered() public {
        address ownerBefore = store.owner();
        store.setNum(1234);
        assertEq(store.num(), 1234, "num must be set through the library");
        assertEq(store.owner(), ownerBefore, "owner must not be clobbered");
    }

    function testOwnerIsDeployer() public {
        assertEq(store.owner(), address(this));
    }
}
