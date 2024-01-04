# size-v2-solidity

Size V2 Solidity

## Coverage

<!-- BEGIN_COVERAGE -->
### FIles

| File                                                   | % Lines          | % Statements      | % Branches       | % Funcs          |
|--------------------------------------------------------|------------------|-------------------|------------------|------------------|
| src/Size.sol                                           | 100.00% (39/39)  | 100.00% (39/39)   | 100.00% (0/0)    | 100.00% (16/16)  |
| src/SizeView.sol                                       | 100.00% (26/26)  | 100.00% (37/37)   | 100.00% (0/0)    | 100.00% (24/24)  |
| src/libraries/LoanLibrary.sol                          | 100.00% (3/3)    | 100.00% (5/5)     | 100.00% (0/0)    | 100.00% (3/3)    |
| src/libraries/MathLibrary.sol                          | 100.00% (1/1)    | 100.00% (3/3)     | 100.00% (0/0)    | 100.00% (1/1)    |
| src/libraries/OfferLibrary.sol                         | 95.83% (23/24)   | 97.78% (44/45)    | 75.00% (6/8)     | 100.00% (5/5)    |
| src/libraries/actions/BorrowAsLimitOrder.sol           | 100.00% (8/8)    | 100.00% (10/10)   | 100.00% (6/6)    | 100.00% (2/2)    |
| src/libraries/actions/BorrowAsMarketOrder.sol          | 100.00% (55/55)  | 100.00% (71/71)   | 90.91% (20/22)   | 100.00% (4/4)    |
| src/libraries/actions/BorrowerExit.sol                 | 96.30% (26/27)   | 97.06% (33/34)    | 80.00% (8/10)    | 100.00% (2/2)    |
| src/libraries/actions/Claim.sol                        | 100.00% (7/7)    | 100.00% (8/8)     | 100.00% (2/2)    | 100.00% (2/2)    |
| src/libraries/actions/Common.sol                       | 100.00% (44/44)  | 100.00% (65/65)   | 100.00% (16/16)  | 92.31% (12/13)   |
| src/libraries/actions/Deposit.sol                      | 100.00% (10/10)  | 100.00% (17/17)   | 100.00% (4/4)    | 100.00% (2/2)    |
| src/libraries/actions/Initialize.sol                   | 100.00% (22/22)  | 100.00% (29/29)   | 100.00% (14/14)  | 100.00% (2/2)    |
| src/libraries/actions/LendAsLimitOrder.sol             | 100.00% (14/14)  | 100.00% (17/17)   | 91.67% (11/12)   | 100.00% (2/2)    |
| src/libraries/actions/LendAsMarketOrder.sol            | 95.65% (22/23)   | 96.43% (27/28)    | 75.00% (6/8)     | 100.00% (2/2)    |
| src/libraries/actions/LiquidateLoan.sol                | 100.00% (27/27)  | 100.00% (34/34)   | 60.00% (6/10)    | 100.00% (2/2)    |
| src/libraries/actions/LiquidateLoanWithReplacement.sol | 100.00% (22/22)  | 100.00% (26/26)   | 75.00% (3/4)     | 100.00% (2/2)    |
| src/libraries/actions/MoveToVariablePool.sol           | 100.00% (13/13)  | 100.00% (16/16)   | 83.33% (5/6)     | 100.00% (2/2)    |
| src/libraries/actions/Repay.sol                        | 100.00% (14/14)  | 100.00% (14/14)   | 87.50% (7/8)     | 100.00% (2/2)    |
| src/libraries/actions/SelfLiquidateLoan.sol            | 100.00% (23/23)  | 100.00% (28/28)   | 80.00% (8/10)    | 100.00% (2/2)    |
| src/libraries/actions/UpdateConfig.sol                 | 100.00% (25/25)  | 100.00% (28/28)   | 100.00% (18/18)  | 100.00% (2/2)    |
| src/libraries/actions/Withdraw.sol                     | 100.00% (10/10)  | 100.00% (17/17)   | 100.00% (4/4)    | 100.00% (2/2)    |
| src/oracle/PriceFeed.sol                               | 100.00% (12/12)  | 100.00% (21/21)   | 100.00% (8/8)    | 100.00% (3/3)    |
| src/token/NonTransferrableToken.sol                    | 100.00% (8/8)    | 100.00% (9/9)     | 100.00% (0/0)    | 100.00% (6/6)    |

### Scenarios

```markdown
┌──────────────────────────────┬────────┐
│           (index)            │ Values │
├──────────────────────────────┼────────┤
│      BorrowAsLimitOrder      │   2    │
│     BorrowAsMarketOrder      │   14   │
│         BorrowerExit         │   4    │
│            Claim             │   3    │
│           Deposit            │   2    │
│         Experiments          │   9    │
│          Initialize          │   3    │
│       LendAsLimitOrder       │   2    │
│      LendAsMarketOrder       │   4    │
│ LiquidateLoanWithReplacement │   5    │
│        LiquidateLoan         │   5    │
│         MathLibrary          │   3    │
│      MoveToVariablePool      │   2    │
│          Multicall           │   2    │
│    NonTransferrableToken     │   7    │
│         Ownable2Step         │   4    │
│          PriceFeed           │   8    │
│            Repay             │   3    │
│      SelfLiquidateLoan       │   6    │
│         UpdateConfig         │   2    │
│           Upgrade            │   2    │
│           Withdraw           │   3    │
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

- Repay should never DoS due to underflow
- If isLiquidatable && liquidator has enough cash, the liquidation should always succeed (requires adding more checks to isLiquidatable)
- When a user self liquidates a SOL, it will improve the collateralization ratio of other SOLs. This is because self liquidating decreases the FOL's face value, so it decreases all SOL's debt
- A self liquidation of a FOL will never leave it as a dust loan
- No loan (FOL/SOL) can ever become a dust loan
- the protocol vault is always solvent (how to check for that?)
- $Credit(i) = FV(i) - \sum\limits_{j~where~Exiter(j)=i}{FV(j)}$ /// For example, when a loan i exits to another j, Exiter(j) = i. This isn't tracked anywhere on-chain, as it's not necessary under the correct accounting conditions, as the loan structure only tracks the folId, not the "originator". But the originator can also be a SOL, when a SOL exits to another SOL. But it can be emitted, which may be used for off-chain metrics, so I guess I'll add that to the event. Also, when doing fuzzing/formal verification, we can also add "ghost variables" to track the "originator", so no need to add it to the protocol, but this concept can be useful in assessing the correct behavior of the exit logic
- The VP utilization ratio should never be greater than 1

## TODOs

- TODO: more scenarios
- TODO: debt compensation
- TODO: origination fee & loan fee
- TODO: VP updates

- finish invariant tests
- add more unit tests where block.timestamp is e.g. "December 29, 2023", so that it is more realistic
- add tests with other types of yield curves (not only flat)
- also add buckets of different sizes, not only spaced by 1 (second), but also 30 days, 1 week, etc etc
- add test for dueDate NOW
- borrowing from yourself you increase your debt without getting any cash, and can put you closer to liquidation
- should withdraw update BorrowOffer? if (user.borrowAsset.free < user.loanOffer.maxAmount) user.loanOffer.maxAmount = user.borrowAsset.free;
- test events
- refactor tests following Sablier v2 naming conventions: `test_Foo`, `testFuzz_Foo`, `test_RevertWhen_Foo`, `testFuzz_RevertWhen_Foo`, `testFork_...`
- test libraries (OfferLibrary.getRate, etc)
- test liquidator profits
- test liquiadtion library collateralRate, etc, and others, for important decimals/etc, hardcoded values
- natspec
- multi-erc20 tokens with different CR per tokens
- review all input validation functions
- gas optimizations
- separate Loan struct
- use solady for tokens or other simple primitives

## Audit remarks

- Check rounding direction of `mulDiv`

## Known limitations

- Protocol does not support rebasing tokens
- Protocol does not support fee-on-transfer tokens
- Protocol does not support tokens with more than 18 decimals
- Protocol only supports tokens compliant with the IERC20Metadata interface
- Protocol only supports pre-vetted tokens
- All features except deposits/withdrawals are paused in case Chainlink oracles are stale
- In cas Chainlink reports a wrong price, the protocol state cannot be guaranteed (invalid liquidations, etc)
- Price feeds must be redeployed and updated on the `Size` smart contract in case any chainlink configuration changes (stale price, decimals)
