// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./MathLibrary.sol";
import "./UserLibrary.sol";

struct Loan {
    uint256 FV;
    uint256 amountFVExited;
    address lender;
    address borrower;
    uint256 dueDate;
    bool repaid;
    uint256 folId; // non-null for SOLs
}

struct VariableLoan {
    address borrower;
    uint256 amountUSDCLentOut;
    uint256 amountCollateral;
}

library LoanLibrary {
    error LoanLibrary__InvalidLoan(uint256 folId);
    error LoanLibrary__InvalidAmount(uint256 amount, uint256 maxExit);

    function isFOL(Loan storage self) public view returns (bool) {
        return self.folId == 0;
    }

    function maxExit(Loan memory self) public view returns (uint256) {
        return self.FV - self.amountFVExited;
    }

    function perc(Loan storage self, Loan[] storage loans) public view returns (uint256) {
        return (PERCENT * maxExit(self)) / (isFOL(self) ? self.FV : loans[self.folId].FV);
    }

    function getDueDate(Loan storage self, Loan[] storage loans) public view returns (uint256) {
        return isFOL(self) ? self.dueDate : loans[self.folId].dueDate;
    }

    // function getLender(
    //     Loan storage self,
    //     Loan[] storage loans
    // ) public view returns (address) {
    //     return isFOL(self) ? self.lender : loans[self.folId].lender;
    // }

    // function getBorrower(
    //     Loan storage self,
    //     Loan[] storage loans
    // ) public view returns (address) {
    //     return isFOL(self) ? self.borrower : loans[self.folId].borrower;
    // }

    function getFOL(Loan storage self, Loan[] storage loans) public view returns (Loan storage) {
        return isFOL(self) ? self : loans[self.folId];
    }

    function lock(Loan storage self, uint256 amount) public view {
        if (amount > maxExit(self)) {
            revert LoanLibrary__InvalidAmount(amount, maxExit(self));
        }
    }

    function isExpired(Loan storage self) public view returns (bool) {
        if (isFOL(self)) {
            return block.timestamp >= self.dueDate;
        } else {
            revert LoanLibrary__InvalidLoan(self.folId);
        }
    }

    function createFOL(
        Loan[] storage loans,
        address lender,
        address borrower,
        uint256 FV,
        uint256 dueDate
    ) public {
        loans.push(
            Loan({
                FV: FV,
                amountFVExited: 0,
                lender: lender,
                borrower: borrower,
                dueDate: dueDate,
                repaid: false,
                folId: 0
            })
        );
    }

    function createSOL(
        Loan[] storage loans,
        uint256 folId,
        address lender,
        address borrower,
        uint256 FV
    ) public {
        Loan memory fol = loans[folId];
        loans.push(
            Loan({
                FV: FV,
                amountFVExited: 0,
                lender: lender,
                borrower: borrower,
                dueDate: fol.dueDate,
                repaid: false,
                folId: folId
            })
        );
    }
}
