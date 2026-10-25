// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// testing3 — cheatcodes
// Foundry's cheatcodes are your time machine, impersonation service,
// and bank: prank (impersonate), deal (set balances), warp (time
// travel). They're how you test paths that would need victims in
// production.
//
// TODO: Complete the three tests using cheatcodes (the contract is
// correct):
//   1. someone ELSE pays — prove their credit lands in their name
//   2. the test contract needs ETH it doesn't have — give it some, then deposit
//   3. time passes — prove the lock expires at the right moment

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

        // TODO: make the NEXT call come from `stranger` with 1 ether

        fail("unreachable — prank the stranger's deposit first");
    }

    function testFundTheTestContract() public {
        // The test contract starts with 0 ETH.

        // TODO: give the test contract 2 ether

        fail("unreachable — deal yourself funds first");
    }

    function testLockExpires() public {
        vault.deposit{value: 1 ether}(1 days);

        // TODO: advance time past the lock, then withdraw successfully

        fail("unreachable — warp past the unlock time first");
    }

    receive() external payable {}
}
