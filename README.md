# size-v2-solidity

Size V2 Solidity

## Coverage

<!-- BEGIN_COVERAGE -->
### FIles

| File                                                              | % Lines           | % Statements      | % Branches       | % Funcs          |
|-------------------------------------------------------------------|-------------------|-------------------|------------------|------------------|
| src/Size.sol                                                      | 100.00% (41/41)   | 100.00% (41/41)   | 100.00% (0/0)    | 100.00% (17/17)  |
| src/SizeView.sol                                                  | 94.44% (17/18)    | 96.43% (27/28)    | 100.00% (0/0)    | 93.75% (15/16)   |
| src/libraries/ConversionLibrary.sol                               | 100.00% (3/3)     | 100.00% (8/8)     | 100.00% (0/0)    | 100.00% (3/3)    |
| src/libraries/Math.sol                                            | 88.89% (16/18)    | 88.89% (24/27)    | 83.33% (5/6)     | 83.33% (5/6)     |
| src/libraries/fixed/FixedLibrary.sol                              | 100.00% (58/58)   | 98.84% (85/86)    | 95.00% (19/20)   | 80.00% (12/15)   |
| src/libraries/fixed/FixedLoanLibrary.sol                          | 0.00% (0/3)       | 0.00% (0/5)       | 100.00% (0/0)    | 0.00% (0/3)      |
| src/libraries/fixed/OfferLibrary.sol                              | 0.00% (0/6)       | 0.00% (0/18)      | 100.00% (0/0)    | 0.00% (0/4)      |
| src/libraries/fixed/YieldCurveLibrary.sol                         | 37.50% (9/24)     | 35.14% (13/37)    | 42.86% (6/14)    | 50.00% (1/2)     |
| src/libraries/fixed/actions/BorrowAsLimitOrder.sol                | 100.00% (5/5)     | 100.00% (5/5)     | 100.00% (2/2)    | 100.00% (2/2)    |
| src/libraries/fixed/actions/BorrowAsMarketOrder.sol               | 100.00% (55/55)   | 100.00% (70/70)   | 95.45% (21/22)   | 100.00% (4/4)    |
| src/libraries/fixed/actions/BorrowerExit.sol                      | 96.30% (26/27)    | 97.06% (33/34)    | 80.00% (8/10)    | 100.00% (2/2)    |
| src/libraries/fixed/actions/Claim.sol                             | 100.00% (8/8)     | 100.00% (10/10)   | 100.00% (2/2)    | 100.00% (2/2)    |
| src/libraries/fixed/actions/Compensate.sol                        | 100.00% (21/21)   | 100.00% (26/26)   | 100.00% (12/12)  | 100.00% (2/2)    |
| src/libraries/fixed/actions/Deposit.sol                           | 92.86% (13/14)    | 95.45% (21/22)    | 83.33% (5/6)     | 100.00% (3/3)    |
| src/libraries/fixed/actions/LendAsLimitOrder.sol                  | 100.00% (11/11)   | 100.00% (12/12)   | 87.50% (7/8)     | 100.00% (2/2)    |
| src/libraries/fixed/actions/LendAsMarketOrder.sol                 | 96.15% (25/26)    | 96.55% (28/29)    | 80.00% (8/10)    | 100.00% (2/2)    |
| src/libraries/fixed/actions/LiquidateFixedLoan.sol                | 100.00% (32/32)   | 100.00% (39/39)   | 58.33% (7/12)    | 100.00% (2/2)    |
| src/libraries/fixed/actions/LiquidateFixedLoanWithReplacement.sol | 100.00% (23/23)   | 100.00% (27/27)   | 75.00% (3/4)     | 100.00% (2/2)    |
| src/libraries/fixed/actions/MoveToVariablePool.sol                | 100.00% (13/13)   | 100.00% (16/16)   | 83.33% (5/6)     | 100.00% (2/2)    |
| src/libraries/fixed/actions/Repay.sol                             | 100.00% (18/18)   | 100.00% (22/22)   | 80.00% (8/10)    | 100.00% (2/2)    |
| src/libraries/fixed/actions/SelfLiquidateFixedLoan.sol            | 100.00% (18/18)   | 100.00% (23/23)   | 75.00% (6/8)     | 100.00% (2/2)    |
| src/libraries/fixed/actions/Withdraw.sol                          | 100.00% (18/18)   | 100.00% (30/30)   | 100.00% (6/6)    | 100.00% (3/3)    |
| src/libraries/general/actions/Initialize.sol                      | 100.00% (42/42)   | 100.00% (47/47)   | 100.00% (22/22)  | 100.00% (7/7)    |
| src/libraries/general/actions/UpdateConfig.sol                    | 100.00% (4/4)     | 100.00% (4/4)     | 100.00% (2/2)    | 100.00% (2/2)    |
| src/libraries/variable/AaveLibrary.sol                            | 92.31% (24/26)    | 95.12% (39/41)    | 100.00% (0/0)    | 50.00% (3/6)     |
| src/libraries/variable/VariableLibrary.sol                        | 93.94% (31/33)    | 93.48% (43/46)    | 50.00% (1/2)     | 66.67% (4/6)     |
| src/oracle/PriceFeed.sol                                          | 100.00% (12/12)   | 100.00% (21/21)   | 100.00% (8/8)    | 100.00% (3/3)    |
| src/proxy/UserProxy.sol                                           | 42.86% (6/14)     | 44.44% (8/18)     | 12.50% (1/8)     | 75.00% (3/4)     |
| src/token/NonTransferrableToken.sol                               | 100.00% (8/8)     | 100.00% (9/9)     | 100.00% (0/0)    | 100.00% (6/6)    |

### Scenarios

```markdown
┌───────────────────────────────────┬────────┐
│              (index)              │ Values │
├───────────────────────────────────┼────────┤
│              BORROW               │   1    │
│        BorrowAsLimitOrder         │   3    │
│        BorrowAsMarketOrder        │   15   │
│           BorrowerExit            │   4    │
│               Claim               │   7    │
│            Compensate             │   6    │
│         ConversionLibrary         │   6    │
│              Deposit              │   2    │
│            Experiments            │   10   │
│            Initialize             │   3    │
│               LOAN                │   2    │
│         LendAsLimitOrder          │   2    │
│         LendAsMarketOrder         │   6    │
│ LiquidateFixedLoanWithReplacement │   5    │
│        LiquidateFixedLoan         │   5    │
│               Math                │   5    │
│        MoveToVariablePool         │   2    │
│             Multicall             │   3    │
│       NonTransferrableToken       │   7    │
│           Ownable2Step            │   4    │
│             PriceFeed             │   8    │
│               REPAY               │   2    │
│               Repay               │   9    │
│      SelfLiquidateFixedLoan       │   6    │
│              TOKENS               │   1    │
│           UpdateConfig            │   3    │
│              Upgrade              │   2    │
│             Withdraw              │   8    │
│            YieldCurve             │   12   │
└───────────────────────────────────┴────────┘
```
<!-- END_COVERAGE -->

## Documentation

- decimals:
  - USDC/aszUSDC: 6
  - WETH/szETH: 18
  - szDebt: 6
  - PriceFeed: 18

## Deployment

```bash
npm run deploy-sepolia
```

## Invariants

- creating a FOL/SOL decreases a offer maxAmount
- you can exit a SOL
- Taking loan with only virtual collateral does not decrease the borrower CR
- Taking loan with real collateral decreases the borrower CR
- The user cannot withdraw more than their deposits
- If isLiquidatable && liquidator has enough cash, the liquidation should always succeed (requires adding more checks to isLiquidatable)
- When a user self liquidates a SOL, it will improve the collateralization ratio of other SOLs. This is because self liquidating decreases the FOL's face value, so it decreases all SOL's debt
- No loan (FOL/SOL) can ever become a dust loan
- the protocol vault is always solvent (how to check for that?)
- $Credit(i) = FV(i) - \sum\limits_{j~where~Exiter(j)=i}{FV(j)}$ /// For example, when a loan i exits to another j, Exiter(j) = i. This isn't tracked anywhere on-chain, as it's not necessary under the correct accounting conditions, as the loan structure only tracks the folId, not the "originator". But the originator can also be a SOL, when a SOL exits to another SOL. But it can be emitted, which may be used for off-chain metrics, so I guess I'll add that to the event. Also, when doing fuzzing/formal verification, we can also add "ghost variables" to track the "originator", so no need to add it to the protocol, but this concept can be useful in assessing the correct behavior of the exit logic
- The VP utilization ratio should never be greater than 1
- the collateral ratio of a loan should always be >= than before, after a partial liquidation. We can apply the same invariant in the fixed rate OB for operations like self liquidations and credit debt compensation

## TODO if there's time

- merge EOA CR and UserProxy CR

## TODO before audit

- gas optimize the 80/20 rule
- add tests for fixed borrows with dueDate now
- review all input validation functions
- add natspec

## TODO before mainnet

- Do the Aave fork, document and automate mitigations
- Learn how to do liquidations in our Aave fork
- add aave tests
- test events
- monitoring
- incident response plan

## Gas optimizations

- separate Loan struct
- refactor tests following Sablier v2 naming conventions: `test_Foo`, `testFuzz_Foo`, `test_RevertWhen_Foo`, `testFuzz_RevertWhen_Foo`, `testFork_...`
- use solady for tokens or other simple primitives

## Notes for auditors

- // @audit Check rounding direction of `FixedPointMath.mulDiv*`
- // @audit Check if borrower == lender == liquidator may cause any issues

## Questions

- Check how Aave does insurance

## Known limitations

- Protocol does not support rebasing tokens
- Protocol does not support fee-on-transfer tokens
- Protocol does not support tokens with more than 18 decimals
- Protocol only supports tokens compliant with the IERC20Metadata interface
- Protocol only supports pre-vetted tokens
- All features except deposits/withdrawals are paused in case Chainlink oracles are stale
- In cas Chainlink reports a wrong price, the protocol state cannot be guaranteed (invalid liquidations, etc)
- Price feeds must be redeployed and updated on the `Size` smart contract in case any chainlink configuration changes (stale price, decimals)
