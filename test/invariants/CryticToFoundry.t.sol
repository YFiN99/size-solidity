// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {TargetFunctions} from "./TargetFunctions.sol";

import {Asserts} from "@chimera/Asserts.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import {Test} from "forge-std/Test.sol";

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        vm.deal(address(USER1), 100e18);
        vm.deal(address(USER2), 100e18);
        vm.deal(address(USER3), 100e18);

        vm.warp(1524785992);
        vm.roll(4370000);

        setup();

        sender = USER1;
    }

    function _setUp(address _user, uint256 _time, uint256 _block) internal {
        sender = _user;
        vm.warp(block.timestamp + _time);
        vm.roll(block.number + _block);
    }

    modifier getSender() override {
        _;
        _checkProperties();
    }

    function precondition(bool) internal virtual override(FoundryAsserts, Asserts) {
        return;
    }

    function _checkProperties() internal {
        assertTrue(property_LOAN(), LOAN);
        assertTrue(property_UNDERWATER(), UNDERWATER);
        assertTrue(property_TOKENS(), TOKENS);
        assertTrue(property_SOLVENCY(), SOLVENCY);
        assertTrue(property_FEES(), FEES);
    }

    function test_CryticToFoundry_01() public {
        deposit(address(0x1fffffffe), 4);
    }

    function test_CryticToFoundry_02() public {
        deposit(0xe11bcd2D4941AA8648b2c1D5e470D915c05CC603, 73899321702418552725334123008022);
    }

    function test_CryticToFoundry_03() public {
        deposit(
            0x64Cf4A4613A8E4C56e81D52Bc814dF43fB6Ac75d,
            115792089237316195423570985008687907853269984665640564039457584007913129639932
        );
        setLiquidityIndex(115792089237316195423570985008687907853269984665640564039457584007913129639934, 3);
        property_TOKENS();
    }

    function test_CryticToFoundry_04() public {
        buyCreditLimit(61610961792943, 745722042769143156660);
        updateConfig(34427929482916198936384567379399524978565095668324743502528967604624539, 84308633);
        sellCreditMarket(
            address(0x0),
            2930762529385342386013132128768,
            2349033066314694823075402460322659131477895613343804352970665415788,
            481460843976435882299533915351829538674179421703829407269908408881959677635,
            false
        );
    }

    function test_CryticToFoundry_05() public {
        buyCreditLimit(11991443917530647420774, 3);
        updateConfig(46481846931432401445888159185091847000024858619702667713489049788141731, 10385809);
        sellCreditMarket(address(0x0), 0, 255950761242656429883442036947612123737672341259439413588850, 605956, false);
    }

    function test_CryticToFoundry_06() public {
        deposit(address(0xdeadbeef), 0);
        buyCreditLimit(627253, 3);
        deposit(address(0x0), 277173003316296293927);
        sellCreditMarket(address(0x0), 0, 8364335607247948167695496674283411717220691865669214800699, 605956, false);
        sellCreditMarket(
            address(0x0), 0, 17217729, 8089560715892272342403863296103953896773539712036938251612026, false
        );
    }

    function test_CryticToFoundry_07() public {
        deposit(address(0xdeadbeef), 0);
        buyCreditLimit(607378, 3);
        deposit(address(0x0), 0);
        sellCreditMarket(address(0x0), 0, 51480107806899221988161571891687667782123974947, 605800, false);
    }

    function test_CryticToFoundry_08() public {
        deposit(address(0xdeadbeef), 0);
        buyCreditLimit(33384594783, 3);
        deposit(address(0x0), 9149686054833342031943887452235404424320189628012854416084);
        sellCreditMarket(address(0x0), 0, 76670736836295901040121558978319704354886418228159, 605956, false);
        updateConfig(
            3760962939656215923299540111674614985114988683331511536101273177295541472406,
            1351984053017908459298206846056544696633775644724223889079548121117739566
        );
    }

    function test_CryticToFoundry_09() public {
        deposit(address(0xdeadbeef), 6650265435768735282694896341184603990418320173531048);
        sellCreditLimit(0);
        deposit(address(0x0), 14110947487286576);
        buyCreditMarket(
            address(0x0),
            0,
            1775610665997594022858846866460267459070968892247915994682862813138757916384,
            280148697151562282203777064572360693677811105921389519391554775108,
            false
        );
    }

    function test_CryticToFoundry_10() public {
        deposit(address(0xdeadbeef), 0);
        buyCreditLimit(615772, 3);
        deposit(address(0x0), 0);
        sellCreditMarket(address(0x0), 0, 147058977595679525986423272625702, 605956, false);
        compensate(0, 90537930272888273525, 7551184);
    }

    function test_CryticToFoundry_11() public {
        deposit(address(0xdeadbeef), 486987982);
        deposit(address(0x0), 542119798154271826);
        updateConfig(3476689163798957933627285661408434842686568751617897946215078674744880122, 1);
        sellCreditLimit(0);
        setLiquidityIndex(1, 0);
        buyCreditMarket(
            address(0x0),
            0,
            560297479045200601233239408702471290199352436977548093015982641843298539,
            22576319848627412381195622757383666471949398566030438813750667,
            false
        );
    }

    function test_CryticToFoundry_12() public {
        deposit(address(0xdeadbeef), 481797977);
        sellCreditLimit(0);
        deposit(address(0x0), 542722934120754506);
        buyCreditMarket(
            address(0x0),
            0,
            308038948465724683836823477037869565199260835768169178060056385273936037,
            22576319848627412381195622757383666471949398566030438813750667,
            false
        );
    }

    function test_CryticToFoundry_13() public {
        deposit(address(0x0), 309646366057719218);
        buyCreditLimit(3660, 125725079549898127780212690292168332883405948303381474);
        deposit(address(0xdeadbeef), 49671462709254420677446753);
        sellCreditMarket(address(0x0), 0, 122457266127183160707598484974950339, 3613, false);
    }

    function test_CryticToFoundry_14() public {
        deposit(address(0xdeadbeef), 486987982);
        deposit(address(0x0), 542119798154271826);
        updateConfig(3476689163798957933627285661408434842686568751617897946215078674744880122, 1);
        sellCreditLimit(0);
        setLiquidityIndex(1, 0);
        buyCreditMarket(
            address(0x0),
            0,
            560297479045200601233239408702471290199352436977548093015982641843298539,
            22576319848627412381195622757383666471949398566030438813750667,
            false
        );
    }

    function test_CryticToFoundry_16() public {
        _setUp(0x0000000000000000000000000000000000020000, 314435 seconds, 29826);
        buyCreditLimit(115792089237316195423570985008687907853269984665640564039457539007913129639937, 183);
        _setUp(0x0000000000000000000000000000000000030000, 599944 seconds, 44);
        setPrice(53041679552025056960350439062206622489044312390915125528741382084316446848209);
        _setUp(0x0000000000000000000000000000000000010000, 604796 seconds, 12382);
        sellCreditLimit(120000001);
        _setUp(0x0000000000000000000000000000000000030000, 553872 seconds, 59522);
        deposit(address(0x636f6e736f6c652e6c6f67), 1300000000000000000);
        _setUp(0x0000000000000000000000000000000000010000, 122098 seconds, 8537);
        deposit(address(0x1fffffffe), 46260777116182966703374715083925636802368898082079057284759778816561030218803);
        _setUp(0x0000000000000000000000000000000000020000, 93520 seconds, 24806);
        setUserConfiguration(82200344721489480218982235675506364504562651035147284862607409369535823663820, true);
        _setUp(0x0000000000000000000000000000000000020000, 145549 seconds, 17067);
        buyCreditLimit(
            27937249680199059681009662930285041174956614364527646328015426872075376238318,
            102385753380358145447186766886670837887333939230873416706960260825848786236013
        );
        _setUp(address(0), 1063497 seconds, 178973);
        _setUp(0x0000000000000000000000000000000000030000, 154798 seconds, 50479);
        buyCreditMarket(
            address(0x0),
            0,
            727690640895543139840570287100089103977809712802750554709389848297092910,
            22576319848627412381195622757383666471949398566030438813750667,
            false
        );
        _setUp(0x0000000000000000000000000000000000010000, 297039 seconds, 48117);
        compensate(
            115792089237316195423570985008687907853269984665640564039457584007913123332736,
            14811637418840987892471287947634039069460809680860362691965659834838991822764,
            115792089237316195423570985008687907853269984665640564039457584007913120481537
        );
    }

    function test_CryticToFoundry_17() public {
        deposit(address(0xdeadbeef), 727891695088401482584375412222945914);
        buyCreditLimit(494101731645502964337137615587161108821235166340036437, 19256442171330545888);
        deposit(address(0x0), 75997482007941151961197221752376131800957703291693);
        sellCreditMarket(
            address(0x0),
            112429428586071743252441594592996183959604223522309146848621,
            538571649109651427164431130745837522007610933891101594830456740549535,
            490001432456401571129481877721428507551041497532414879280151630114225149258,
            false
        );
        _setUp(USER1, 319950 seconds, 23482);
        updateConfig(
            115792089237316195423570985008687907853269984665640564039457584007913113871936,
            115792089237316195423570985008687907853269984665640564039457569007913129639935
        );
        _checkProperties();
    }

    function test_CryticToFoundry_18() public {
        deposit(address(0xdeadbeef), 206844940486);
        sellCreditLimit(0);
        deposit(address(0x0), 2096225315717814455);
        buyCreditMarket(
            address(0x0),
            0,
            11494494789619123927668443190759460608727890911652141532574701887477808,
            279907969654346637931868298245803458544236274649037,
            false
        );
        setPrice(0);
        _checkProperties();
    }

    function test_CryticToFoundry_19() public {
        sender = 0x73F9899D3d3d316628495068081b0c6273a7e6f8;
        updateConfig(20282, 4139);
        sender = 0x000000000000000000000000000000000000576b;
        deposit(
            0xd4443AB29eB60fB165Ac44c78EAB847c65273f86,
            6909931560136680612532959958641161722744310460888515753602252511774
        );
        sender = 0x0000000000000000000000000000000000000865;
        buyCreditLimit(503302198636119108, 16564);
        sender = 0xb6549931239171cf71d16630F7d0d1B249d628cf;
        setLiquidityIndex(10435, 47929067690);
        sender = 0x000000000000000000000000000000000000056E;
        deposit(0xD46B656c565DaeE4cd3Df82CD6fAf380d02850C7, 240164310623208855283514273872052000299846518);
        sender = 0x0000000000000000000000000000000000003713;
        sellCreditMarket(0x0000000000000000000000000000000000001150, 6294, 4557, 4638, true);
        _checkProperties();
    }
}
