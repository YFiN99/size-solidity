// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console2 as console} from "forge-std/console2.sol";

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {SizeValidations} from "./SizeValidations.sol";
import {SizeVirtualCollateral} from "./SizeVirtualCollateral.sol";
import {SizeRealCollateral} from "./SizeRealCollateral.sol";

import {YieldCurve} from "./libraries/YieldCurveLibrary.sol";
import {OfferLibrary, LoanOffer, BorrowOffer} from "./libraries/OfferLibrary.sol";
import {UserLibrary, User} from "./libraries/UserLibrary.sol";
import {RealCollateralLibrary, RealCollateral} from "./libraries/RealCollateralLibrary.sol";
import {Math, PERCENT} from "./libraries/MathLibrary.sol";
import {LoanLibrary, Loan} from "./libraries/LoanLibrary.sol";

import {IPriceFeed} from "./oracle/IPriceFeed.sol";

import {ISize} from "./interfaces/ISize.sol";

contract Size is
    ISize,
    SizeValidations,
    SizeVirtualCollateral,
    SizeRealCollateral,
    Initializable,
    Ownable2StepUpgradeable,
    UUPSUpgradeable
{
    using OfferLibrary for LoanOffer;
    using RealCollateralLibrary for RealCollateral;
    using LoanLibrary for Loan;
    using LoanLibrary for Loan[];
    using UserLibrary for User;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        IPriceFeed _priceFeed,
        uint256 _CROpening,
        uint256 _CRLiquidation,
        uint256 _collateralPercPremiumToLiquidator,
        uint256 _collateralPercPremiumToBorrower
    ) public initializer {
        __Ownable_init(_owner);
        __Ownable2Step_init();
        __UUPSUpgradeable_init();

        _validateNonNull(_owner);
        _validateNonNull(address(_priceFeed));
        _validateCollateralRatio(_CROpening);
        _validateCollateralRatio(_CRLiquidation);
        _validateCollateralRatio(_CROpening, _CRLiquidation);
        _validateCollateralPercPremium(_collateralPercPremiumToLiquidator);
        _validateCollateralPercPremium(_collateralPercPremiumToBorrower);
        _validateCollateralPercPremium(_collateralPercPremiumToLiquidator, _collateralPercPremiumToBorrower);

        priceFeed = _priceFeed;
        CROpening = _CROpening;
        CRLiquidation = _CRLiquidation;
        collateralPercPremiumToLiquidator = _collateralPercPremiumToLiquidator;
        collateralPercPremiumToBorrower = _collateralPercPremiumToBorrower;

        LoanOffer memory lo;
        loanOffers.push(lo);
        BorrowOffer memory bo;
        borrowOffers.push(bo);
        Loan memory l;
        loans.push(l);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function deposit(uint256 cash, uint256 eth) public {
        users[msg.sender].cash.free += cash;
        users[msg.sender].eth.free += eth;
    }

    function withdraw(uint256 cash, uint256 eth) public {
        users[msg.sender].cash.free -= cash;
        users[msg.sender].eth.free -= eth;

        _validateUserHealthy(msg.sender);
    }

    function lendAsLimitOrder(uint256 maxAmount, uint256 maxDueDate, YieldCurve calldata curveRelativeTime)
        public
        returns (uint256)
    {
        loanOffers.push(
            LoanOffer({
                lender: msg.sender,
                maxAmount: maxAmount,
                maxDueDate: maxDueDate,
                curveRelativeTime: curveRelativeTime
            })
        );

        return loanOffers.length - 1;
    }

    function borrowAsLimitOrder(uint256 maxAmount, YieldCurve calldata curveRelativeTime) public returns (uint256) {
        borrowOffers.push(
            BorrowOffer({borrower: msg.sender, maxAmount: maxAmount, curveRelativeTime: curveRelativeTime})
        );

        return borrowOffers.length - 1;
    }

    function lendAsMarketOrder(uint256 borrowOfferId, uint256 dueDate, uint256 amount) public {
        BorrowOffer storage offer = borrowOffers[borrowOfferId];
        User storage lender = users[msg.sender];

        if (amount > offer.maxAmount) {
            revert ISize.InvalidAmount(offer.maxAmount);
        }
        if (lender.cash.free < amount) {
            revert ISize.NotEnoughCash(lender.cash.free, amount);
        }

        // uint256 rate = offer.getRate(dueDate);
        // uint256 r = (PERCENT + rate);

        (dueDate);

        emit TODO();
        revert();
    }

    // decreases lender free cash
    // increases borrower free cash

    // if FOL
    //  increases borrower locked eth
    //  increases borrower totDebtCoveredByRealCollateral

    // decreases loan offer max amount

    // creates new loans
    function borrowAsMarketOrder(
        uint256 loanOfferId,
        uint256 amount,
        uint256 dueDate,
        uint256[] memory virtualCollateralLoansIds
    ) public {
        LoanOffer storage offer = loanOffers[loanOfferId];
        User storage lender = users[offer.lender];

        _validateDueDate(dueDate);
        if (amount > offer.maxAmount) {
            revert ISize.InvalidAmount(offer.maxAmount);
        }
        if (lender.cash.free < amount) {
            revert ISize.NotEnoughCash(lender.cash.free, amount);
        }

        //  amountIn: Amount of future cashflow to exit
        //  amountOut: Amount of cash to borrow at present time

        //  NOTE: The `amountOutLeft` is going to be decreased as more and more SOLs are created
        uint256 amountOutLeft = _borrowWithVirtualCollateral(loanOfferId, amount, dueDate, virtualCollateralLoansIds);

        // TODO cover the remaining amount with real collateral
        if (amountOutLeft > 0) {
            _borrowWithRealCollateral(loanOfferId, amountOutLeft, dueDate);
        }

        _validateUserHealthy(msg.sender);
    }

    // decreases loanOffer lender free cash
    // increases msg.sender free cash
    // maintains loan borrower accounting

    // decreases loanOffers max amount
    // increases loan amountFVExited

    // creates a new SOL
    function exit(uint256 loanId, uint256 amount, uint256 dueDate, uint256[] memory loanOfferIds)
        public
        returns (uint256)
    {
        // NOTE: The exit is equivalent to a spot swap for exact amount in wheres
        // - the exiting lender is the taker
        // - the other lenders are the makers
        // The swap traverses the `loanOfferIds` as they if they were ticks with liquidity in an orderbook
        Loan storage loan = loans[loanId];
        if (loan.lender != msg.sender) revert ISize.InvalidLender();
        if (amount == 0) revert ISize.InvalidAmount(amount);
        if (amount > loan.getCredit()) {
            revert ISize.InvalidAmount(loan.getCredit());
        }

        uint256 amountInLeft = amount;
        for (uint256 i = 0; i < loanOfferIds.length; ++i) {
            if (amountInLeft == 0) {
                // No more amountIn to swap
                break;
            }

            LoanOffer storage loanOffer = loanOffers[loanOfferIds[i]];
            uint256 r = PERCENT + loanOffer.getRate(dueDate);
            uint256 deltaAmountIn;
            uint256 deltaAmountOut;
            // @audit check rounding direction
            if (amountInLeft >= loanOffer.maxAmount) {
                deltaAmountIn = (r * loanOffer.maxAmount) / PERCENT;
                deltaAmountOut = loanOffer.maxAmount;
            } else {
                deltaAmountIn = amountInLeft;
                deltaAmountOut = (deltaAmountIn * PERCENT) / r;
            }

            loans.createSOL(loanId, loanOffer.lender, msg.sender, deltaAmountIn);
            users[loanOffer.lender].cash.transfer(users[msg.sender].cash, deltaAmountOut);
            loanOffer.maxAmount -= deltaAmountOut;
            amountInLeft -= deltaAmountIn;
        }

        return amountInLeft;
    }

    // decreases borrower free cash
    // increases protocol free cash
    // increases lender claim(???)

    // decreases borrower locked eth??
    // decreases borrower totDebtCoveredByRealCollateral

    // sets loan to repaid
    function repay(uint256 loanId, uint256 amount) public {
        Loan storage loan = loans[loanId];
        User storage borrower = users[loan.borrower];
        User storage protocol = users[address(this)];
        if (!loan.isFOL()) {
            revert ISize.InvalidLoanId(loanId);
        }
        if (loan.repaid) {
            revert ISize.NothingToRepay();
        }
        if (amount < loan.FV) {
            // NOTE partial repayment currently unsupported
            revert ISize.NotEnoughCash(amount, loan.FV);
        }
        if (borrower.cash.free < amount) {
            revert ISize.NotEnoughCash(borrower.cash.free, amount);
        }

        borrower.cash.transfer(protocol.cash, amount);
        borrower.totDebtCoveredByRealCollateral -= loan.FV;
        loan.repaid = true;
    }

    function _liquidationSwap(User storage liquidator, User storage borrower, uint256 amountUSDC, uint256 amountETH)
        private
    {
        liquidator.cash.transfer(borrower.cash, amountUSDC);
        borrower.cash.lock(amountUSDC);
        borrower.eth.unlock(amountETH);
        borrower.eth.transfer(liquidator.eth, amountETH);
    }

    function liquidateBorrower(address _borrower) public returns (uint256, uint256) {
        User storage borrower = users[_borrower];
        User storage liquidator = users[msg.sender];

        if (!isLiquidatable(_borrower)) {
            revert ISize.NotLiquidatable();
        }
        // @audit partial liquidations? maybe not, just assume flash loan??
        if (liquidator.cash.free < borrower.totDebtCoveredByRealCollateral) {
            revert ISize.NotEnoughCash(liquidator.cash.free, borrower.totDebtCoveredByRealCollateral);
        }

        uint256 temp = borrower.cash.locked;

        (temp);

        uint256 amountUSDC = borrower.totDebtCoveredByRealCollateral - borrower.cash.locked;

        uint256 targetAmountETH = (amountUSDC * 1e18) / priceFeed.getPrice();
        uint256 actualAmountETH = Math.min(targetAmountETH, borrower.eth.locked);
        if (actualAmountETH < targetAmountETH) {
            // @audit why would this happen? should we prevent the liquidator from doing it?
            emit LiquidationAtLoss(targetAmountETH - actualAmountETH);
        }

        _liquidationSwap(liquidator, borrower, amountUSDC, actualAmountETH);

        borrower.totDebtCoveredByRealCollateral = 0;

        return (actualAmountETH, targetAmountETH);
    }

    function liquidateLoan(uint256 loanId) public {
        (loanId);
        emit TODO();
        revert();
    }
}
