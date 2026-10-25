// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// capstone3 — the recovery runbook, executable
// A pause that traps user funds is a hostage situation, not a circuit
// breaker. The recovery doctrine this curriculum trains:
//
//   WHEN PAUSED:
//     new deposits      → blocked   (stop the bleeding)
//     verdict releases  → blocked   (halt during an incident)
//     user EXITS        → allowed   (anyone can always leave)
//
// "Users can always exit" is what makes pausing defensible to users,
// auditors, and regulators alike. The contract below has the doctrine
// exactly backwards: deposits and the verdict path run during a pause,
// while user withdrawals are frozen with it. This drill encodes the
// runbook as a test you can point to in an audit review.
//
// TODO: Fix the pause wiring — deposit and releaseTo must respect the
// pause; withdraw must NOT. Keep checks-effects-interactions in
// withdraw.

import "forge-std/Test.sol";

contract RecoveryVault {
    error Paused();

    address public operator;
    bool public paused;

    mapping(address => uint256) public balances;

    event Deposited(address indexed who, uint256 amount);
    event Withdrawn(address indexed who, uint256 amount);

    constructor() {
        operator = msg.sender;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "not operator");
        _;
    }

    function setPaused(bool p) external onlyOperator {
        paused = p;
    }

    // TODO: block while paused (stop the bleeding)
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // TODO: block while paused (the verdict path halts during incidents)
    function releaseTo(address to, uint256 amount) external onlyOperator {
        require(balances[to] >= type(uint256).max, "unreachable in drill");
        payable(to).transfer(amount);
    }

    // BROKEN: the pause freezes the EXIT — users are trapped
    function withdraw() external {
        require(!paused, Paused()); // TODO: the exit must never be pausable

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    receive() external payable {}
}

contract Capstone3Test is Test {
    RecoveryVault vault;
    address user;

    function setUp() public {
        vault = new RecoveryVault();
        user = makeAddr("user");
        vm.deal(user, 10 ether);
    }

    function testDepositBlockedWhilePaused() public {
        vault.setPaused(true);
        vm.prank(user);
        vm.expectRevert(RecoveryVault.Paused.selector);
        vault.deposit{value: 1 ether}();

        assertEq(address(vault).balance, 0);
    }

    function testReleaseBlockedWhilePaused() public {
        vm.prank(user);
        vault.deposit{value: 1 ether}();
        vault.setPaused(true);

        // The verdict path is frozen during an incident.
        vm.expectRevert(RecoveryVault.Paused.selector);
        vault.releaseTo(makeAddr("attacker"), 1 ether);
    }

    function testUsersCanAlwaysExit() public {
        vm.prank(user);
        vault.deposit{value: 5 ether}();

        vault.setPaused(true); // incident!

        vm.prank(user);
        vault.withdraw(); // ...and the exit still opens

        assertEq(user.balance, 10 ether, "user made whole during the incident");
    }
}
