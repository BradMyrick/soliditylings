// You can also write unit tests in Solidity!
// soliditylings uses Foundry behind the scenes, so you can write normal tests
// using forge-std.
import "forge-std/Test.sol";

contract Intro2 {
    function returnTrue() public pure returns (bool) {
        return true;
    }
}

contract Intro2Test is Test {
    Intro2 public intro;

    function setUp() public {
        intro = new Intro2();
    }

    function testReturnTrue() public {
        assertTrue(intro.returnTrue(), "Should return true");
    }
}
