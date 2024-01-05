// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BaseTest} from "./BaseTest.sol";

import {LoanOffer, OfferLibrary} from "@src/libraries/OfferLibrary.sol";
import {User} from "@src/libraries/UserLibrary.sol";

contract LendAsLimitOrderTest is BaseTest {
    using OfferLibrary for LoanOffer;

    function test_LendAsLimitOrder_lendAsLimitOrder_adds_loanOffer_to_orderbook() public {
        _deposit(alice, 100e18, 100e18);
        assertTrue(_state().alice.user.loanOffer.isNull());
        _lendAsLimitOrder(alice, 50e18, 12, 1.01e18, 12);
        assertTrue(!_state().alice.user.loanOffer.isNull());
    }
}
