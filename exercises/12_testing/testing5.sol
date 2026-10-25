// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// testing5 — fuzzing & invariants (Foundry's superpower)
// Property tests don't check examples — they check LAWS:
//
//   fuzz test:   for ANY input the compiler can generate, X holds
//   invariant:   after ANY sequence of handler calls, X still holds
//
// The handler below tracks a GHOST VARIABLE — the total a depositor
// has actually deposited — and the invariant asserts the vault's
// bookkeeping can never drift from it, no matter what sequence of
// deposits forge throws at it. That drift-proof bookkeeping is the
// foundation of "the operator can never move depositor funds": there
// is no path in this vault that changes `deposited` except the
// depositor's own deposit and withdraw.
//
// The contract and handler are correct. Your job is the FUZZ test:
//
// TODO: `testDepositBookKeeping` takes a fuzzed `uint128 amount`,
// funds the caller, deposits it, and asserts BOTH the vault's balance
// AND its `deposited` accounting match for ANY amount.

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

    // The ONLY way out: your own key, your own balance.
    function withdraw() external {
        uint256 amount = deposited[msg.sender];
        deposited[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}

/// Invariant handler: exposes deposits (and only deposits) with a
/// ghost variable tracking what the vault OUGHT to owe.
contract VaultHandler is Test {
    HonestVault public vault;
    address public depositor;
    uint256 public ghostDeposits; // what the vault should owe now

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

    /// INVARIANT: vault bookkeeping == ghost accounting, after ANY
    /// sequence of handler calls.
    function invariant_bookkeepingNeverDrifts() public {
        assertEq(
            handler.vault().deposited(handler.depositor()),
            handler.ghostDeposits(),
            "vault must owe exactly what was deposited, nothing else can move it"
        );
    }

    /// FUZZ: the accounting holds for ANY deposit amount.
    /// TODO: complete the fuzz test described in the header.
    function testDepositBookKeeping(uint128 amount) public {
        HonestVault vault = new HonestVault();

        // TODO: deal, deposit, and assert both balance and `deposited`

        fail("unreachable if your assertions held");
    }
}
