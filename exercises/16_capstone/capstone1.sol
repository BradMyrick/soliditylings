// SPDX-License-Identifier: MIT
pragma solidity ^0.8.38;

// capstone1 — THE ESCROW (everything you've trained for)
// One contract on Base: funds held until a signed verdict releases
// them, refunds that work without the platform, and no path where
// the operator can move a counterparty's money.
//
//   signature — EIP-712 typed verdict signed by the trusted verifier
//   audience  — the digest binds (escrowId, recipient): verdicts
//               cannot be replayed across escrows or redirected
//   expiry    — the verdict's deadline is signed and enforced
//   refund    — self-serve after the escrow's own deadline: permissionless
//   pause     — the operator can FREEZE new actions, never REDIRECT funds
//
// The digest machinery is given (you built it in signatures4/5).
// Your job is the enforcement. Trace every check before you write it:
// checks → effects → interactions, and state is the lock.
//
// TODO: complete `releaseWithVerdict` and `refund`.

import "forge-std/Test.sol";

contract VerdictEscrow {
    // ---------- types ----------
    struct Escrow {
        address buyer;
        address seller;
        uint256 amount;
        uint256 refundAfter; // buyer's self-serve unlock time
        Status status;
    }

    enum Status {
        Empty,
        Active,
        Released,
        Refunded
    }

    // ---------- storage ----------
    address public immutable verifier; // the CTO's signing key (off-chain)
    address public operator; // platform: may pause, may NEVER move funds
    bool public paused;

    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(bytes32 => Escrow) public escrows;
    mapping(bytes32 => bool) public verdictUsed; // replay guard per escrow

    // ---------- errors ----------
    error Paused();
    error NotVerifier();
    error Expired();
    error AlreadyUsed();
    error NotRefundable();
    error WrongStatus();

    // ---------- events (the runbook's eyes) ----------
    event EscrowCreated(bytes32 indexed id, address indexed buyer, address indexed seller, uint256 amount, uint256 refundAfter);
    event Released(bytes32 indexed id, address indexed seller, uint256 amount);
    event Refunded(bytes32 indexed id, address indexed buyer, uint256 amount);
    event PauseChanged(bool paused);

    bytes32 private constant VERDICT_TYPEHASH =
        keccak256("Verdict(uint256 escrowId,address recipient,uint256 amount,uint256 deadline)");

    // ---------- constructor ----------
    constructor(address _verifier) {
        verifier = _verifier;
        operator = msg.sender;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SaifuroEscrow")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    // ---------- given: the exact digest the verifier signs ----------
    function verdictDigest(
        bytes32 escrowId,
        address recipient,
        uint256 amount,
        uint256 deadline
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(VERDICT_TYPEHASH, escrowId, recipient, amount, deadline));
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    // ---------- given: split a 65-byte sig ----------
    function _split(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65, "bad length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    // ---------- given: creation + pause plumbing ----------
    function create(address seller, uint256 lifetime) external payable returns (bytes32 id) {
        require(!paused, Paused());
        require(msg.value > 0, "empty");
        require(lifetime > 0, "bad lifetime");

        id = keccak256(abi.encode(msg.sender, seller, msg.value, block.timestamp, block.prevrandao));
        require(escrows[id].status == Status.Empty, "id collision");

        escrows[id] = Escrow(msg.sender, seller, msg.value, block.timestamp + lifetime, Status.Active);
        emit EscrowCreated(id, msg.sender, seller, msg.value, block.timestamp + lifetime);
    }

    function setPaused(bool p) external {
        require(msg.sender == operator, "not operator");
        paused = p;
        emit PauseChanged(p);
    }

    // ---------- TODO: the verdict release ----------
    // The CTO's key signs verdictDigest(id, seller, escrowAmount, deadline).
    // Note the digest binds the ESCROW'S OWN amount — a verdict always
    // names the full deal, so partial releases cannot strand funds.
    // Enforce, in order: pause, status, replay, expiry, signature —
    // then pay. CEI. Emit Released.
    function releaseWithVerdict(
        bytes32 id,
        uint256 deadline,
        bytes memory sig
    ) external {
        // TODO 1: reject when paused
        // TODO 2: reject a used verdict (before status — spent is spent)
        // TODO 3: reject unless the escrow is Active
        // TODO 4: reject an expired deadline
        // TODO 5: recover the signer over verdictDigest(id, seller, escrow.amount, deadline);
        //         reject unless it equals `verifier` (audience is bound by the digest)
        // TODO 6: consume the verdict, transition state, payout, emit Released
    }

    // ---------- TODO: the self-serve refund ----------
    // After refundAfter, the buyer exits WITHOUT anyone's permission —
    // and a pause must NOT trap user funds (read the runbook note in
    // capstone3 before deciding whether refund checks `paused`).
    function refund(bytes32 id) external {
        // TODO: only Active, only after refundAfter; CEI; emit Refunded
    }

    receive() external payable {}
}

contract Capstone1Test is Test {
    VerdictEscrow escrow;
    uint256 constant VERIFIER_PK = 0xCE0;
    address verifierAddr;
    address buyer = makeAddr("buyer");
    address seller = makeAddr("seller");

    function setUp() public {
        verifierAddr = vm.addr(VERIFIER_PK);
        escrow = new VerdictEscrow(verifierAddr);
        vm.deal(buyer, 100 ether);
    }

    function createDefault() internal returns (bytes32 id) {
        vm.prank(buyer);
        id = escrow.create{value: 1 ether}(seller, 7 days);
    }

    function signVerdict(bytes32 id, address recipient, uint256 amount, uint256 deadline)
        internal
        view
        returns (bytes memory)
    {
        bytes32 digest = escrow.verdictDigest(id, recipient, amount, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(VERIFIER_PK, digest);
        return abi.encodePacked(r, s, v);
    }

    // Convenience: sign a verdict for the escrow's OWN amount.
    function signForEscrow(bytes32 id, uint256 deadline) internal view returns (bytes memory) {
        (, address seller, uint256 amount, , ) = escrow.escrows(id);
        return signVerdict(id, seller, amount, deadline);
    }

    function testHappyRelease() public {
        bytes32 id = createDefault();
        uint256 deadline = block.timestamp + 1 days;
        bytes memory sig = signForEscrow(id, deadline);

        escrow.releaseWithVerdict(id, deadline, sig);

        assertEq(seller.balance, 1 ether);
        (, , , , VerdictEscrow.Status s) = escrow.escrows(id);
        assertTrue(s == VerdictEscrow.Status.Released);
        assertTrue(escrow.verdictUsed(id));
    }

    function testWrongSignerRejected() public {
        bytes32 id = createDefault();
        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest = escrow.verdictDigest(id, seller, 1 ether, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBA0BAD, digest);

        vm.expectRevert(VerdictEscrow.NotVerifier.selector);
        escrow.releaseWithVerdict(id, deadline, abi.encodePacked(r, s, v));
    }

    function testExpiredVerdictRejected() public {
        bytes32 id = createDefault();
        uint256 deadline = block.timestamp - 1;
        bytes memory sig = signForEscrow(id, deadline);

        vm.expectRevert(VerdictEscrow.Expired.selector);
        escrow.releaseWithVerdict(id, deadline, sig);
    }

    function testVerdictReplayRejected() public {
        bytes32 id = createDefault();
        uint256 deadline = block.timestamp + 1 days;
        bytes memory sig = signForEscrow(id, deadline);

        escrow.releaseWithVerdict(id, deadline, sig);
        vm.expectRevert(VerdictEscrow.AlreadyUsed.selector);
        escrow.releaseWithVerdict(id, deadline, sig);
    }

    function testAudienceIsBound() public {
        bytes32 id = createDefault();
        bytes32 otherId;
        vm.prank(buyer);
        otherId = escrow.create{value: 2 ether}(seller, 7 days);

        // A verdict signed for `otherId` must not release `id`.
        uint256 deadline = block.timestamp + 1 days;
        bytes memory sig = signForEscrow(otherId, deadline);

        vm.expectRevert(VerdictEscrow.NotVerifier.selector); // digest mismatch
        escrow.releaseWithVerdict(id, deadline, sig);
    }

    function testSelfServeRefund() public {
        bytes32 id = createDefault();
        vm.warp(block.timestamp + 8 days);

        vm.prank(makeAddr("stranger")); // a total stranger triggers it
        escrow.refund(id);

        assertEq(buyer.balance, 100 ether, "buyer made whole");
        (, , , , VerdictEscrow.Status s) = escrow.escrows(id);
        assertTrue(s == VerdictEscrow.Status.Refunded);
    }

    function testRefundBeforeTimeoutRejected() public {
        bytes32 id = createDefault();
        vm.expectRevert(VerdictEscrow.NotRefundable.selector);
        escrow.refund(id);
    }

    function testPauseBlocksReleaseNotRefund() public {
        bytes32 id = createDefault();
        escrow.setPaused(true);

        uint256 deadline = block.timestamp + 1 days;
        bytes memory sig = signForEscrow(id, deadline);
        vm.expectRevert(VerdictEscrow.Paused.selector);
        escrow.releaseWithVerdict(id, deadline, sig);

        // ...but users can always EXIT during an incident (capstone3)
        vm.warp(block.timestamp + 8 days);
        escrow.refund(id);
        assertEq(buyer.balance, 100 ether);
    }

    function testOperatorCannotSteal() public {
        // The operator's ONLY powers are pause/unpause — there is no
        // path from operator to funds. This test is the requirement.
        bytes32 id = createDefault();
        escrow.setPaused(true);
        escrow.setPaused(false);
        // (any function the operator could call is now exhausted)
        (, , , , VerdictEscrow.Status s) = escrow.escrows(id);
        assertTrue(s == VerdictEscrow.Status.Active, "escrow untouched");
        assertEq(address(escrow).balance, 1 ether, "funds untouched");
    }
}
