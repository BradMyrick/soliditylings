// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract PausableVault {
    bool public paused;
    address public owner;

    event Paused();
    event Unpaused();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    function deposit() external payable whenNotPaused {}

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    receive() external payable {}
}

contract Ownership1Test is Test {
    PausableVault vault;

    function setUp() public {
        vault = new PausableVault();
    }

    function testDepositBlockedWhilePaused() public {
        vault.pause();
        vm.expectRevert();
        vault.deposit{value: 1 ether}();

        vault.unpause();
        vault.deposit{value: 1 ether}();
        assertEq(address(vault).balance, 1 ether);
    }

    function testOnlyOwnerCanPause() public {
        vm.prank(address(0xBA0BAD));
        vm.expectRevert();
        vault.pause();
        assertFalse(vault.paused(), "stranger must not pause");
    }

    function testOnlyOwnerCanUnpause() public {
        vault.pause();
        vm.prank(address(0xBA0BAD));
        vm.expectRevert();
        vault.unpause();
        assertTrue(vault.paused());
    }

    receive() external payable {}
}
