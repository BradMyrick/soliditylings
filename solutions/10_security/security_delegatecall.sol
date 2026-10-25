// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract NumberLibrary {
    // slot 0 in the library
    uint256 public num;

    function setNum(uint256 v) external {
        num = v;
    }
}

contract Storage {
    // FIXED layout: slot 0 mirrors the library's slot 0, so the
    // delegated write lands on `num` and never on `owner`.
    uint256 public num; // slot 0 — aligned with NumberLibrary.num
    address public owner; // slot 1
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
