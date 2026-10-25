// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract TimedVault {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public unlockAt;

    function deposit(uint256 secondsLocked) external payable {
        balances[msg.sender] += msg.value;
        unlockAt[msg.sender] = block.timestamp + secondsLocked;
    }

    function withdraw() external {
        require(block.timestamp >= unlockAt[msg.sender], "locked");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

contract Testing3Test is Test {
    TimedVault vault;

    function setUp() public {
        vault = new TimedVault();
    }

    function testSomeoneElseDeposits() public {
        address stranger = address(0x5);
        vm.deal(stranger, 1 ether);

        vm.prank(stranger); // the next call comes from the stranger
        vault.deposit{value: 1 ether}(1 days);

        assertEq(vault.balances(stranger), 1 ether, "credit in THEIR name");
    }

    function testFundTheTestContract() public {
        vm.deal(address(this), 2 ether);

        vault.deposit{value: 2 ether}(1 days);
        assertEq(vault.balances(address(this)), 2 ether);
    }

    function testLockExpires() public {
        vault.deposit{value: 1 ether}(1 days);

        vm.warp(block.timestamp + 1 days + 1);
        vault.withdraw();

        assertEq(vault.balances(address(this)), 0, "unlocked and withdrawn");
    }

    receive() external payable {}
}
