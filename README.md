# size-v2-solidity

Size V2 Solidity

## Coverage

<!-- BEGIN_COVERAGE -->
### FIles

| File                                                   | % Lines           | % Statements      | % Branches       | % Funcs          |
|--------------------------------------------------------|-------------------|-------------------|------------------|------------------|
| src/Size.sol                                           | 100.00% (41/41)   | 100.00% (41/41)   | 100.00% (0/0)    | 100.00% (17/17)  |
| src/SizeView.sol                                       | 94.44% (17/18)    | 96.30% (26/27)    | 100.00% (0/0)    | 93.75% (15/16)   |
| src/libraries/LoanLibrary.sol                          | 0.00% (0/3)       | 0.00% (0/5)       | 100.00% (0/0)    | 0.00% (0/3)      |
| src/libraries/MathLibrary.sol                          | 94.74% (18/19)    | 96.77% (30/31)    | 83.33% (5/6)     | 100.00% (7/7)    |
| src/libraries/OfferLibrary.sol                         | 0.00% (0/6)       | 0.00% (0/18)      | 100.00% (0/0)    | 0.00% (0/4)      |
| src/libraries/YieldCurveLibrary.sol                    | 37.50% (9/24)     | 35.14% (13/37)    | 42.86% (6/14)    | 50.00% (1/2)     |
| src/libraries/actions/BorrowAsLimitOrder.sol           | 100.00% (5/5)     | 100.00% (5/5)     | 100.00% (2/2)    | 100.00% (2/2)    |
| src/libraries/actions/BorrowAsMarketOrder.sol          | 100.00% (54/54)   | 100.00% (69/69)   | 95.45% (21/22)   | 100.00% (4/4)    |
| src/libraries/actions/BorrowerExit.sol                 | 96.30% (26/27)    | 97.06% (33/34)    | 80.00% (8/10)    | 100.00% (2/2)    |
| src/libraries/actions/Claim.sol                        | 100.00% (7/7)     | 100.00% (8/8)     | 100.00% (2/2)    | 100.00% (2/2)    |
| src/libraries/actions/Common.sol                       | 100.00% (59/59)   | 98.85% (86/87)    | 95.00% (19/20)   | 81.25% (13/16)   |
| src/libraries/actions/Compensate.sol                   | 100.00% (20/20)   | 100.00% (26/26)   | 100.00% (12/12)  | 100.00% (2/2)    |
| src/libraries/actions/Deposit.sol                      | 100.00% (10/10)   | 100.00% (17/17)   | 100.00% (4/4)    | 100.00% (2/2)    |
| src/libraries/actions/Initialize.sol                   | 100.00% (22/22)   | 100.00% (29/29)   | 100.00% (14/14)  | 100.00% (2/2)    |
| src/libraries/actions/LendAsLimitOrder.sol             | 100.00% (11/11)   | 100.00% (12/12)   | 87.50% (7/8)     | 100.00% (2/2)    |
| src/libraries/actions/LendAsMarketOrder.sol            | 96.15% (25/26)    | 96.55% (28/29)    | 80.00% (8/10)    | 100.00% (2/2)    |
| src/libraries/actions/LiquidateLoan.sol                | 100.00% (33/33)   | 100.00% (39/39)   | 58.33% (7/12)    | 100.00% (2/2)    |
| src/libraries/actions/LiquidateLoanWithReplacement.sol | 100.00% (23/23)   | 100.00% (27/27)   | 75.00% (3/4)     | 100.00% (2/2)    |
| src/libraries/actions/MoveToVariablePool.sol           | 100.00% (14/14)   | 100.00% (17/17)   | 83.33% (5/6)     | 100.00% (2/2)    |
| src/libraries/actions/Repay.sol                        | 100.00% (18/18)   | 100.00% (22/22)   | 80.00% (8/10)    | 100.00% (2/2)    |
| src/libraries/actions/SelfLiquidateLoan.sol            | 100.00% (19/19)   | 100.00% (23/23)   | 75.00% (6/8)     | 100.00% (2/2)    |
| src/libraries/actions/UpdateConfig.sol                 | 100.00% (25/25)   | 100.00% (28/28)   | 100.00% (18/18)  | 100.00% (2/2)    |
| src/libraries/actions/Withdraw.sol                     | 100.00% (14/14)   | 100.00% (25/25)   | 100.00% (4/4)    | 100.00% (2/2)    |
| src/oracle/PriceFeed.sol                               | 100.00% (12/12)   | 100.00% (21/21)   | 100.00% (8/8)    | 100.00% (3/3)    |
| src/token/NonTransferrableToken.sol                    | 100.00% (8/8)     | 100.00% (9/9)     | 100.00% (0/0)    | 100.00% (6/6)    |

### Scenarios

```markdown
┌──────────────────────────────┬────────┐
│           (index)            │ Values │
├──────────────────────────────┼────────┤
│            BORROW            │   1    │
│      BorrowAsLimitOrder      │   3    │
│     BorrowAsMarketOrder      │   15   │
│         BorrowerExit         │   4    │
│            Claim             │   7    │
│          Compensate          │   6    │
│           Deposit            │   2    │
│         Experiments          │   10   │
│          Initialize          │   3    │
│             LOAN             │   1    │
│       LendAsLimitOrder       │   2    │
│      LendAsMarketOrder       │   6    │
│ LiquidateLoanWithReplacement │   5    │
│        LiquidateLoan         │   5    │
│             Math             │   11   │
│      MoveToVariablePool      │   2    │
│          Multicall           │   3    │
│    NonTransferrableToken     │   7    │
│         Ownable2Step         │   4    │
│          PriceFeed           │   8    │
│            REPAY             │   2    │
│            Repay             │   9    │
│      SelfLiquidateLoan       │   6    │
│         UpdateConfig         │   2    │
│           Upgrade            │   2    │
│           Withdraw           │   5    │
│          YieldCurve          │   12   │
└──────────────────────────────┴────────┘
```
<!-- END_COVERAGE -->

## Documentation

- Inside the protocol, all values are expressed in WAD (18 decimals), including price feed decimals and percentages

## Invariants

- creating a FOL/SOL decreases a offer maxAmount
- you can exit a SOL
- Taking loan with only virtual collateral does not decrease the borrower CR
- Taking loan with real collateral decreases the borrower CR

- If isLiquidatable && liquidator has enough cash, the liquidation should always succeed (requires adding more checks to isLiquidatable)
- When a user self liquidates a SOL, it will improve the collateralization ratio of other SOLs. This is because self liquidating decreases the FOL's face value, so it decreases all SOL's debt
- No loan (FOL/SOL) can ever become a dust loan
- the protocol vault is always solvent (how to check for that?)
- $Credit(i) = FV(i) - \sum\limits_{j~where~Exiter(j)=i}{FV(j)}$ /// For example, when a loan i exits to another j, Exiter(j) = i. This isn't tracked anywhere on-chain, as it's not necessary under the correct accounting conditions, as the loan structure only tracks the folId, not the "originator". But the originator can also be a SOL, when a SOL exits to another SOL. But it can be emitted, which may be used for off-chain metrics, so I guess I'll add that to the event. Also, when doing fuzzing/formal verification, we can also add "ghost variables" to track the "originator", so no need to add it to the protocol, but this concept can be useful in assessing the correct behavior of the exit logic
- The VP utilization ratio should never be greater than 1

## TODO before testnet

- finish invariant tests
- test for dueDate NOW
- events tests
- origination fee & loan fee
- VP

## TODO before audit

- review all input validation functions
- natspec

## Gas optimizations

- separate Loan struct
- refactor tests following Sablier v2 naming conventions: `test_Foo`, `testFuzz_Foo`, `test_RevertWhen_Foo`, `testFuzz_RevertWhen_Foo`, `testFork_...`
- use solady for tokens or other simple primitives

## Notes for auditors

- // @audit Check rounding direction of `FixedPointMath.mulDiv*`
- // @audit Check if borrower == lender == liquidator may cause any issues

## Known limitations

- Protocol does not support rebasing tokens
- Protocol does not support fee-on-transfer tokens
- Protocol does not support tokens with more than 18 decimals
- Protocol only supports tokens compliant with the IERC20Metadata interface
- Protocol only supports pre-vetted tokens
- All features except deposits/withdrawals are paused in case Chainlink oracles are stale
- In cas Chainlink reports a wrong price, the protocol state cannot be guaranteed (invalid liquidations, etc)
- Price feeds must be redeployed and updated on the `Size` smart contract in case any chainlink configuration changes (stale price, decimals)
