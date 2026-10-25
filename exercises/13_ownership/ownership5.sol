// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// ownership5 — renouncing ownership
// The endgame of trust minimization: an owner whose job is DONE. Once
// parameters are set, an owner is pure risk (key leak = exploit, not
// rescue). Renouncing sets owner to address(0) — after which every
// onlyOwner path is permanently dead. DeFi drama has hinged on exactly
// this: renounced too early (can't fix bugs) vs never (can rug).
//
// TODO: Implement `renounceOwnership` — only the owner may press the
// button, and it must set owner to address(0) and emit Renounced().
// (Irreversible by design: address(0) can never sign.)

import "forge-std/Test.sol";

contract Renouncable {
    address public owner;

    event Renounced();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // TODO: irrevocably give up ownership
    function renounceOwnership() external {
    }

    function setFee(uint256 f) external onlyOwner {
        // fee = f (setter for demonstration)
        fee = f;
    }

    uint256 public fee;
}

contract Ownership5Test is Test {
    Renouncable target;

    function setUp() public {
        target = new Renouncable(); // test contract = owner
    }

    function testRenounceKillsAdminPlane() public {
        target.setFee(5); // still possible while owned
        assertEq(target.fee(), 5);

        target.renounceOwnership();
        assertEq(target.owner(), address(0), "owner must be zeroed");

        vm.expectRevert(); // address(0) can never call this again
        target.setFee(10);
        assertEq(target.fee(), 5, "fee is frozen forever");
    }

    function testOnlyOwnerCanRenounce() public {
        vm.prank(address(0xBA0BAD));
        vm.expectRevert();
        target.renounceOwnership();
        assertEq(target.owner(), address(this));
    }
}
