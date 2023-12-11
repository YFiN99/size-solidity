// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console2 as console} from "forge-std/Test.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Size} from "@src/Size.sol";
import {InitializeParams} from "@src/libraries/actions/Initialize.sol";
import {CollateralToken} from "@src/token/CollateralToken.sol";
import {BorrowToken} from "@src/token/BorrowToken.sol";
import {DebtToken} from "@src/token/DebtToken.sol";
import {SizeMock} from "./mocks/SizeMock.sol";
import {PriceFeedMock} from "./mocks/PriceFeedMock.sol";
import {YieldCurve, YieldCurveLibrary} from "@src/libraries/YieldCurveLibrary.sol";
import {AssertsHelper} from "./helpers/AssertsHelper.sol";
import {User, UserView} from "@src/libraries/UserLibrary.sol";
import {CollateralToken} from "@src/token/CollateralToken.sol";
import {BorrowToken} from "@src/token/BorrowToken.sol";
import {DebtToken} from "@src/token/DebtToken.sol";
import {WETH} from "./mocks/WETH.sol";
import {USDC} from "./mocks/USDC.sol";

contract BaseTest is Test, AssertsHelper {
    event TODO();

    SizeMock public size;
    PriceFeedMock public priceFeed;
    WETH public weth;
    USDC public usdc;
    CollateralToken public collateralToken;
    BorrowToken public borrowToken;
    DebtToken public debtToken;

    address public alice = address(0x10000);
    address public bob = address(0x20000);
    address public candy = address(0x30000);
    address public james = address(0x40000);
    address public liquidator = address(0x50000);
    address public protocolVault = address(0x60000);
    address public feeRecipient = address(0x70000);
    address public protocol;

    struct Vars {
        UserView alice;
        UserView bob;
        UserView candy;
        UserView james;
        UserView liquidator;
        uint256 protocolCollateralAmount;
        uint256 protocolBorrowAmount;
        uint256 feeRecipientCollateralAmount;
        uint256 feeRecipientBorrowAmount;
    }

    function setUp() public {
        priceFeed = new PriceFeedMock(address(this));
        weth = new WETH();
        usdc = new USDC();
        collateralToken = new CollateralToken(address(this), "Size ETH", "szETH");
        borrowToken = new BorrowToken(address(this), "Size USDC", "szUSDC");
        debtToken = new DebtToken(address(this), "Size Debt Token", "szDebt");
        InitializeParams memory params = InitializeParams({
            owner: address(this),
            priceFeed: address(priceFeed),
            collateralAsset: address(weth),
            borrowAsset: address(usdc),
            collateralToken: address(collateralToken),
            borrowToken: address(borrowToken),
            debtToken: address(debtToken),
            crOpening: 1.5e4,
            crLiquidation: 1.3e4,
            collateralPercentagePremiumToLiquidator: 0.3e4,
            collateralPercentagePremiumToBorrower: 0.1e4,
            protocolVault: protocolVault,
            feeRecipient: feeRecipient
        });
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(new SizeMock()),
            abi.encodeCall(
                Size.initialize,
                (params)
            )
        );
        protocol = address(proxy);

        collateralToken.transferOwnership(protocol);
        borrowToken.transferOwnership(protocol);
        debtToken.transferOwnership(protocol);

        size = SizeMock(address(proxy));

        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(candy, "candy");
        vm.label(james, "james");
        vm.label(liquidator, "liquidator");
        vm.label(protocol, "protocol");

        priceFeed.setPrice(1337e18);
    }

    function _deposit(address user, IERC20Metadata token, uint256 value) internal {
        _deposit(user, address(token), value);
    }

    function _deposit(address user, address token, uint256 value) internal {
        deal(token, user, value);
        vm.prank(user);
        IERC20Metadata(token).approve(address(size), value);
        vm.prank(user);
        size.deposit(token, value);
    }

    function _withdraw(address user, IERC20Metadata token, uint256 value) internal {
        _withdraw(user, address(token), value);
    }

    function _withdraw(address user, address token, uint256 value) internal {
        vm.prank(user);
        size.withdraw(token, value);
    }

    function _deposit(address user, uint256 collateralAssetValue, uint256 debtAssetValue) internal {
        _deposit(user, weth, collateralAssetValue);
        _deposit(user, usdc, debtAssetValue);
    }

    function _lendAsLimitOrder(
        address lender,
        uint256 maxAmount,
        uint256 maxDueDate,
        uint256 rate,
        uint256 timeBucketsLength
    ) internal {
        YieldCurve memory curve = YieldCurveLibrary.getFlatRate(timeBucketsLength, rate);
        vm.prank(lender);
        size.lendAsLimitOrder(maxAmount, maxDueDate, curve.timeBuckets, curve.rates);
    }

    function _borrowAsMarketOrder(address borrower, address lender, uint256 amount, uint256 dueDate)
        internal
        returns (uint256)
    {
        return _borrowAsMarketOrder(borrower, lender, amount, dueDate, false);
    }

    function _borrowAsMarketOrder(address borrower, address lender, uint256 amount, uint256 dueDate, bool exactAmountIn)
        internal
        returns (uint256)
    {
        uint256[] memory virtualCollateralLoansIds;
        return _borrowAsMarketOrder(borrower, lender, amount, dueDate, exactAmountIn, virtualCollateralLoansIds);
    }

    function _borrowAsMarketOrder(
        address borrower,
        address lender,
        uint256 amount,
        uint256 dueDate,
        uint256[] memory virtualCollateralLoansIds
    ) internal returns (uint256) {
        return _borrowAsMarketOrder(borrower, lender, amount, dueDate, false, virtualCollateralLoansIds);
    }

    function _borrowAsMarketOrder(
        address borrower,
        address lender,
        uint256 amount,
        uint256 dueDate,
        bool exactAmountIn,
        uint256[] memory virtualCollateralLoansIds
    ) internal returns (uint256) {
        vm.prank(borrower);
        size.borrowAsMarketOrder(lender, amount, dueDate, exactAmountIn, virtualCollateralLoansIds);
        return size.activeLoans();
    }

    function _borrowAsLimitOrder(
        address borrower,
        uint256 maxAmount,
        uint256[] memory timeBuckets,
        uint256[] memory rates
    ) internal {
        vm.prank(borrower);
        size.borrowAsLimitOrder(maxAmount, timeBuckets, rates);
    }

    function _exit(address user, uint256 loanId, uint256 amount, uint256 dueDate, address[] memory lendersToExitTo)
        internal
        returns (uint256)
    {
        vm.prank(user);
        size.exit(loanId, amount, dueDate, lendersToExitTo);
        return size.activeLoans();
    }

    function _repay(address user, uint256 loanId) internal {
        vm.prank(user);
        size.repay(loanId);
    }

    function _claim(address user, uint256 loanId) internal {
        vm.prank(user);
        size.claim(loanId);
    }

    function _liquidateLoan(address user, uint256 loanId) internal {
        vm.prank(user);
        size.liquidateLoan(loanId);
    }

    function _state() internal view returns (Vars memory vars) {
        vars.alice = size.getUserView(alice);
        vars.bob = size.getUserView(bob);
        vars.candy = size.getUserView(candy);
        vars.james = size.getUserView(james);
        vars.liquidator = size.getUserView(liquidator);
        vars.protocolCollateralAmount = collateralToken.balanceOf(protocolVault);
        vars.protocolBorrowAmount = borrowToken.balanceOf(protocolVault);
        vars.feeRecipientCollateralAmount = collateralToken.balanceOf(feeRecipient);
        vars.feeRecipientBorrowAmount = borrowToken.balanceOf(feeRecipient);
    }

    function _setPrice(uint256 price) internal {
        vm.prank(address(this));
        priceFeed.setPrice(price);
    }
}
