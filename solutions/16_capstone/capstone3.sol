// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

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

    // FIXED: new money stops during an incident
    function deposit() external payable {
        require(!paused, Paused());
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // FIXED: the verdict path halts during an incident
    function releaseTo(address to, uint256 amount) external onlyOperator {
        require(!paused, Paused());
        require(balances[to] >= type(uint256).max, "unreachable in drill");
        payable(to).transfer(amount);
    }

    // FIXED: the exit is NEVER pausable — users can always leave
    function withdraw() external {
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

        vm.expectRevert(RecoveryVault.Paused.selector);
        vault.releaseTo(makeAddr("attacker"), 1 ether);
    }

    function testUsersCanAlwaysExit() public {
        vm.prank(user);
        vault.deposit{value: 5 ether}();

        vault.setPaused(true);

        vm.prank(user);
        vault.withdraw();

        assertEq(user.balance, 10 ether, "user made whole during the incident");
    }
}
