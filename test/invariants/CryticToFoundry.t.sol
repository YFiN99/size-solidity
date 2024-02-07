// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {TargetFunctions} from "./TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {Test} from "forge-std/Test.sol";

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        vm.deal(address(USER1), 100e18);
        vm.deal(address(USER2), 100e18);
        vm.deal(address(USER3), 100e18);

        setup();
    }

    modifier getSender() override {
        sender = uint160(msg.sender) % 3 == 0
            ? address(USER1)
            : uint160(msg.sender) % 3 == 1 ? address(USER2) : address(USER3);
        _;
    }

    function test_BORROW_02() public {
        deposit(address(0xdeadbeef), 0);
        lendAsLimitOrder(0, 10667226, 451124);
        borrowAsMarketOrder(
            address(0x1e),
            1,
            299999999999999999,
            true,
            14221329489769958708126347564797299640365746048626527781107915342306360762091,
            47700905178432190716842576859681767948209730775316858409394951552214610302274
        );
    }

    function test_REPAY_01() public {
        deposit(address(0x0), 0);
        deposit(address(0xdeadbeef), 91460117);
        borrowAsLimitOrder(4907270871702042502, 5894179853816920);
        lendAsMarketOrder(address(0x0), 19031769674707116036212, 5004820998700516064, false);
        repay(115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }

    function test_REPAY_01_2() public {
        deposit(address(0xdeadbeef), 0);
        deposit(address(0x0), 0);
        lendAsLimitOrder(0, 3471498, 0);
        borrowAsMarketOrder(
            address(0x0),
            24574995402710635646614640190156820935535387820397,
            90229103640261999611339698052518587384522780478451,
            false,
            0,
            17145422572889695645779948228995886701899200731
        );
        repay(0);
    }

    function test_LOAN_05() public {
        deposit(address(0xdeadbeef), 0);
        deposit(address(0x0), 0);
        lendAsLimitOrder(0, 4640020, 0);
        borrowAsMarketOrder(
            address(0x0),
            7104076085823381970015930982381262816774162739483,
            152749325598820291654851530442320910523826499512205,
            false,
            0,
            20428906037535863295274218098285099272042586872
        );
        try this.repay(0) {} catch {}
        assertTrue(invariant_LOAN());
    }

    function test_TOKENS_02() public {
        deposit(address(0xdeadbeef), 0);
        deposit(address(0x0), 0);
        borrowAsLimitOrder(916546381152797237939, 0);
        lendAsMarketOrder(
            address(0x0),
            92305619202371949356587162660862238281715327889380582040,
            1863291514473264810244393466401690158851286397212901300078,
            false
        );
        withdraw(address(0xdeadbeef), 13329553271505273202379607076657725967833385000643676496066523999450361133825);
    }

    function test_LOAN_05_2() public {
        deposit(address(0xdeadbeef), 0);
        lendAsLimitOrder(0, 3621625, 0);
        deposit(address(0x0), 0);
        borrowAsLimitOrder(5048456819674352758, 0);
        lendAsMarketOrder(address(0x0), 258039800465518346279984, 5099702327371656704, false);
        borrowAsMarketOrder(
            address(0x0),
            24567389056832842508335833822010096740,
            27260363475244470506343419575607945454,
            false,
            6860839812748166727224665369457896,
            0
        );
        assertTrue(invariant_LOAN());
    }

    function test_DEPOSIT_1() public {
        deposit(address(0x0000000000000000000000000000000000002029), 1997);
        assertTrue(invariant_TOKENS_01());
    }
}
