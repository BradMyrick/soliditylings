// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

import "forge-std/Test.sol";

contract HonestVault {
    mapping(address => uint256) public deposited;
    address public immutable operator;

    constructor() {
        operator = msg.sender;
    }

    function deposit() external payable {
        deposited[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = deposited[msg.sender];
        deposited[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

contract VaultHandler is Test {
    HonestVault public vault;
    address public depositor;
    uint256 public ghostDeposits;

    constructor() {
        vault = new HonestVault();
        depositor = makeAddr("depositor");
        vm.deal(depositor, 100 ether);
    }

    function deposit(uint128 amount) external {
        uint256 amt = uint256(amount) % 10 ether;
        vm.prank(depositor);
        vault.deposit{value: amt}();
        ghostDeposits += amt;
    }
}

contract Testing5Test is Test {
    VaultHandler handler;

    function setUp() public {
        handler = new VaultHandler();
        targetContract(address(handler));
    }

    function invariant_bookkeepingNeverDrifts() public {
        assertEq(
            handler.vault().deposited(handler.depositor()),
            handler.ghostDeposits(),
            "vault must owe exactly what was deposited, nothing else can move it"
        );
    }

    function testDepositBookKeeping(uint128 amount) public {
        HonestVault vault = new HonestVault();

        vm.deal(address(this), uint256(amount));
        vault.deposit{value: uint256(amount)}();

        assertEq(address(vault).balance, uint256(amount), "balance received");
        assertEq(vault.deposited(address(this)), uint256(amount), "recorded for ANY amount");
    }

    receive() external payable {}
}
