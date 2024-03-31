// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SizeStorage, State} from "@src/SizeStorage.sol";
import {Math, PERCENT} from "@src/libraries/Math.sol";

import {
    CREDIT_POSITION_ID_START,
    CreditPosition,
    DEBT_POSITION_ID_START,
    DebtPosition,
    LoanLibrary,
    LoanStatus
} from "@src/libraries/fixed/LoanLibrary.sol";
import {UpdateConfig} from "@src/libraries/general/actions/UpdateConfig.sol";

import {IAToken} from "@aave/interfaces/IAToken.sol";
import {IPool} from "@aave/interfaces/IPool.sol";
import {NonTransferrableToken} from "@src/token/NonTransferrableToken.sol";

import {AccountingLibrary} from "@src/libraries/fixed/AccountingLibrary.sol";
import {RiskLibrary} from "@src/libraries/fixed/RiskLibrary.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {BorrowOffer, LoanOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";
import {User} from "@src/libraries/fixed/UserLibrary.sol";
import {
    InitializeDataParams,
    InitializeFeeConfigParams,
    InitializeOracleParams,
    InitializeRiskConfigParams
} from "@src/libraries/general/actions/Initialize.sol";
import {VariablePoolLibrary} from "@src/libraries/variable/VariablePoolLibrary.sol";

struct UserView {
    User user;
    address account;
    uint256 collateralTokenBalance;
    uint256 borrowATokenBalance;
    uint256 debtBalance;
}

struct DataView {
    uint256 nextDebtPositionId;
    uint256 nextCreditPositionId;
    IERC20Metadata underlyingCollateralToken;
    IERC20Metadata underlyingBorrowToken;
    IPool variablePool;
    NonTransferrableToken collateralToken;
    IAToken borrowAToken;
    NonTransferrableToken debtToken;
}

/// @title SizeView
/// @notice View methods for the Size protocol
abstract contract SizeView is SizeStorage {
    using OfferLibrary for LoanOffer;
    using OfferLibrary for BorrowOffer;
    using LoanLibrary for DebtPosition;
    using LoanLibrary for CreditPosition;
    using LoanLibrary for State;
    using RiskLibrary for State;
    using VariablePoolLibrary for State;
    using AccountingLibrary for State;
    using UpdateConfig for State;

    function collateralRatio(address user) external view returns (uint256) {
        return state.collateralRatio(user);
    }

    function isUserUnderwater(address user) external view returns (bool) {
        return state.isUserUnderwater(user);
    }

    function isDebtPositionLiquidatable(uint256 debtPositionId) external view returns (bool) {
        return state.isDebtPositionLiquidatable(debtPositionId);
    }

    function getOverdueDebt(uint256 debtPositionId) external view returns (uint256) {
        return state.getDebtPosition(debtPositionId).getTotalDebt();
    }

    function getDueDateDebt(uint256 debtPositionId) external view returns (uint256) {
        return state.getDebtPosition(debtPositionId).getDueDateDebt();
    }

    function getAPR(uint256 debtPositionId) external view returns (uint256) {
        DebtPosition memory debtPosition = state.getDebtPosition(debtPositionId);
        uint256 maturity = debtPosition.dueDate - debtPosition.startDate;
        uint256 ratePerMaturity = Math.mulDivDown(debtPosition.faceValue, PERCENT, debtPosition.issuanceValue) - PERCENT;
        return Math.ratePerMaturityToAPR(ratePerMaturity, maturity);
    }

    function debtTokenAmountToCollateralTokenAmount(uint256 borrowATokenAmount) external view returns (uint256) {
        return state.debtTokenAmountToCollateralTokenAmount(borrowATokenAmount);
    }

    function feeConfig() external view returns (InitializeFeeConfigParams memory) {
        return state.feeConfigParams();
    }

    function riskConfig() external view returns (InitializeRiskConfigParams memory) {
        return state.riskConfigParams();
    }

    function oracle() external view returns (InitializeOracleParams memory) {
        return state.oracleParams();
    }

    function data() external view returns (DataView memory) {
        return DataView({
            nextDebtPositionId: state.data.nextDebtPositionId,
            nextCreditPositionId: state.data.nextCreditPositionId,
            underlyingCollateralToken: state.data.underlyingCollateralToken,
            underlyingBorrowToken: state.data.underlyingBorrowToken,
            variablePool: state.data.variablePool,
            collateralToken: state.data.collateralToken,
            borrowAToken: state.data.borrowAToken,
            debtToken: state.data.debtToken
        });
    }

    function getUserView(address user) external view returns (UserView memory) {
        return UserView({
            user: state.data.users[user],
            account: user,
            collateralTokenBalance: state.data.collateralToken.balanceOf(user),
            borrowATokenBalance: state.borrowATokenBalanceOf(user),
            debtBalance: state.data.debtToken.balanceOf(user)
        });
    }

    function isDebtPositionId(uint256 debtPositionId) external view returns (bool) {
        return state.isDebtPositionId(debtPositionId);
    }

    function isCreditPositionId(uint256 creditPositionId) external view returns (bool) {
        return state.isCreditPositionId(creditPositionId);
    }

    function getDebtPosition(uint256 debtPositionId) external view returns (DebtPosition memory) {
        return state.getDebtPosition(debtPositionId);
    }

    function getCreditPosition(uint256 creditPositionId) external view returns (CreditPosition memory) {
        return state.getCreditPosition(creditPositionId);
    }

    function getLoanStatus(uint256 positionId) external view returns (LoanStatus) {
        return state.getLoanStatus(positionId);
    }

    function repayFee(uint256 issuanceValue, uint256 startDate, uint256 dueDate, uint256 repayFeeAPR)
        external
        pure
        returns (uint256)
    {
        return LoanLibrary.repayFee(issuanceValue, startDate, dueDate, repayFeeAPR);
    }

    function getPositionsCount() external view returns (uint256, uint256) {
        return (
            state.data.nextDebtPositionId - DEBT_POSITION_ID_START,
            state.data.nextCreditPositionId - CREDIT_POSITION_ID_START
        );
    }

    function getBorrowOfferAPR(address borrower, uint256 dueDate) external view returns (uint256) {
        BorrowOffer memory offer = state.data.users[borrower].borrowOffer;
        if (offer.isNull()) {
            revert Errors.NULL_OFFER();
        }
        if (dueDate < block.timestamp) {
            revert Errors.PAST_DUE_DATE(dueDate);
        }
        return offer.getAPRByDueDate(state.oracle.variablePoolBorrowRateFeed, dueDate);
    }

    function getLoanOfferAPR(address lender, uint256 dueDate) external view returns (uint256) {
        LoanOffer memory offer = state.data.users[lender].loanOffer;
        if (offer.isNull()) {
            revert Errors.NULL_OFFER();
        }
        if (dueDate < block.timestamp) {
            revert Errors.PAST_DUE_DATE(dueDate);
        }
        return offer.getAPRByDueDate(state.oracle.variablePoolBorrowRateFeed, dueDate);
    }

    function getDebtPositionAssignedCollateral(uint256 debtPositionId) external view returns (uint256) {
        DebtPosition memory debtPosition = state.getDebtPosition(debtPositionId);
        return state.getDebtPositionAssignedCollateral(debtPosition);
    }

    function getCreditPositionProRataAssignedCollateral(uint256 creditPositionId) external view returns (uint256) {
        CreditPosition memory creditPosition = state.getCreditPosition(creditPositionId);
        return state.getCreditPositionProRataAssignedCollateral(creditPosition);
    }
}
