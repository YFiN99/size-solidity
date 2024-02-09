// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {LoanStatus} from "@src/libraries/fixed/LoanLibrary.sol";

/// @title Events
library Errors {
    error USER_IS_LIQUIDATABLE(address account, uint256 cr);
    error NULL_ADDRESS();
    error NULL_AMOUNT();
    error NULL_MAX_DUE_DATE();
    error NULL_ARRAY();
    error TIME_BUCKETS_NOT_STRICTLY_INCREASING();
    error ARRAY_LENGTHS_MISMATCH();
    error INVALID_TOKEN(address token);
    error INVALID_KEY(bytes32 key);
    error INVALID_COLLATERAL_RATIO(uint256 cr);
    error INVALID_COLLATERAL_PERCENTAGE_PREMIUM(uint256 percentage);
    error INVALID_COLLATERAL_PERCENTAGE_PREMIUM_SUM(uint256 sum);
    error INVALID_LIQUIDATION_COLLATERAL_RATIO(uint256 crOpening, uint256 crLiquidation);
    error PAST_DUE_DATE(uint256 dueDate);
    error PAST_MAX_DUE_DATE(uint256 maxDueDate);
    error DUE_DATE_LOWER_THAN_LOAN_DUE_DATE(uint256 dueDate, uint256 loanDueDate);
    error DUE_DATE_NOT_COMPATIBLE(uint256 loanToRepayId, uint256 loanToCompensateId);
    error DUE_DATE_GREATER_THAN_MAX_DUE_DATE(uint256 dueDate, uint256 maxDueDate);
    error DUE_DATE_OUT_OF_RANGE(uint256 dueDate, uint256 minDueDate, uint256 maxDueDate);
    error INVALID_LENDER(address account);
    error INVALID_LOAN_OFFER(address lender);
    error INVALID_BORROW_OFFER(address borrower);
    error INVALID_LOAN_STATUS(uint256 loanId, LoanStatus actual, LoanStatus expected);

    error BORROWER_IS_NOT_LENDER(address borrower, address lender);
    error COMPENSATOR_IS_NOT_BORROWER(address compensator, address borrower);
    error LIQUIDATOR_IS_NOT_LENDER(address liquidator, address lender);
    error EXITER_IS_NOT_BORROWER(address exiter, address borrower);
    error REPAYER_IS_NOT_BORROWER(address repayer, address borrower);

    error NOT_ENOUGH_BORROW_ATOKEN_BALANCE(uint256 balance, uint256 required);
    error CREDIT_LOWER_THAN_MINIMUM_CREDIT(uint256 faceValue, uint256 minimumCreditBorrowAToken);
    error CREDIT_LOWER_THAN_MINIMUM_CREDIT_OPENING(uint256 faceValue, uint256 minimumCreditBorrowAToken);

    error ONLY_FOL_CAN_BE_REPAID(uint256 loanId);
    error ONLY_FOL_CAN_BE_COMPENSATED(uint256 loanId);
    error ONLY_FOL_CAN_BE_EXITED(uint256 loanId);
    error LOAN_ALREADY_REPAID(uint256 loanId);
    error LOAN_NOT_REPAID(uint256 loanId);

    error NOT_LIQUIDATABLE(address account);
    error LOAN_NOT_LIQUIDATABLE(uint256 loanId, uint256 cr, LoanStatus status);
    error LOAN_NOT_SELF_LIQUIDATABLE(uint256 loanId, uint256 cr, LoanStatus status);
    error COLLATERAL_RATIO_BELOW_MINIMUM_COLLATERAL_RATIO(uint256 collateralRatio, uint256 minimumCollateralRatio);
    error COLLATERAL_RATIO_BELOW_RISK_COLLATERAL_RATIO(
        address account, uint256 collateralRatio, uint256 riskCollateralRatio
    );
    error LIQUIDATION_NOT_AT_LOSS(uint256 loanId, uint256 assignedCollateral, uint256 debtCollateral);

    error INVALID_DECIMALS(uint8 decimals);
    error INVALID_PRICE(address aggregator, int256 price);
    error STALE_PRICE(address aggregator, uint256 updatedAt);
    error NULL_STALE_PRICE();

    error PROXY_CALL_FAILED(address target, bytes data);

    error COLLATERAL_TOKEN_CAP_EXCEEDED(uint256 cap, uint256 amount);
    error BORROW_ATOKEN_CAP_EXCEEDED(uint256 cap, uint256 amount);
    error DEBT_TOKEN_CAP_EXCEEDED(uint256 cap, uint256 amount);

    error NOT_SUPPORTED();
}
