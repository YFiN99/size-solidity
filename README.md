# size-v2-solidity

![Size](./size.jpeg)

Size is an order book based fixed rate lending protocol with an integrated variable pool.

Initial pairs supported:

- ETH: Collateral token
- USDC: Borrow/Lend token

Target networks:

- Ethereum mainnet
- Base

## Documentation

### Overview, Accounting and Protocol Design

- [Whitepaper](https://size-lending.gitbook.io/size-v2/)

### Technical overview

#### Architecture

The architecture of Size v2 was inspired by [dYdX v2](https://github.com/dydxprotocol/solo), with the following design goals:

- Upgradeability
- Modularity
- Overcome [EIP-170](https://eips.ethereum.org/EIPS/eip-170)'s contract code size limit of 24kb
- Maintaining the protocol invariants after each user interaction (["FREI-PI" pattern](https://www.nascent.xyz/idea/youre-writing-require-statements-wrong))

For that purpose, the contract is deployed behind an UUPS-Upgradeable proxy, and contains a single entrypoint, `Size.sol`. External libraries are used, and a single `State storage` variable is passed to them via `delegatecall`s. All user-facing functions have the same pattern:

```solidity
state.validateFunction(params);
state.executeFunction(params);
state.validateInvariant(params);
```

The `Multicall` pattern is also available to allow users to perform a sequence of multiple actions, such as depositing borrow tokens, liquidating an underwater borrower, and withdrawing all liquidated collateral.

Additional safety features were employed, such as different levels of Access Control (ADMIN, PAUSER_ROLE, KEEPER_ROLE), and Pause.

#### Tokens

In order to address donation and reentrancy attacks, the following measures were adopted:

- No usage of native ether, only wrapped ether (WETH)
- Underlying borrow and collateral tokens, such as USDC and WETH, are converted 1:1 into protocol tokens via `deposit`, which mints `aszUSDC` and `szWETH`, and received back via `withdraw`, which burns protocol tokens 1:1 in exchange of the underlying tokens.

#### Maths

All mathematical operations are implemented with explicit rounding (`mulDivUp` or `mulDivDown`) using Solady's [FixedPointMathLib](https://github.com/Vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol).

Decimal amounts are preserved until a conversion is necessary, and performed via the `ConversionLibrary`:

- USDC/aszUSDC: 6 decimals
- szDebt: 6 decimals (same as borrow token)
- WETH/szETH: 18 decimals
- VariablePoolPriceFeed (ETH/USDC): 18 decimals
- MarketBorrowRateFeed (USDC): 18 decimals

All percentages are expressed in 18 decimals. For example, a 150% liquidation collateral ratio is represented as 1500000000000000000.

#### Variable Pool

In order to interact with Size's Variable Pool (Aave v3 fork), a proxy pattern is employed, which creates user Vault proxies using OpenZeppelin Clone's library to deploy copies on demand. This way, each address can have an individual health factor on Size's Variable Pool (Aave v3 fork). The `Vault` contract is owned by the `Size` contract, which can perform arbitrary calls on behalf of the user. For example, when a `deposit` is performed on `Size`, it creates a `Vault`, if needed, which then executes a `supply` on Size's Variable Pool (Aave v3 fork). This way, all deposited `USDC` can be lent out through variable rates until a fixed-rate loan is matched and created on the orderbook.

When an account executes `supply` into Size's Variable Pool (Aave v3 fork), the `aszUSDC` token is minted 1:1. This is an instance of `AToken`, an interest-bearing rebasing token that represents users' USDC available for variable-rate loans, which grows according to a variable interest rate equation.

#### Oracles

##### Variable Pool Price Feed

Since both `Size` contract (fixed-rate orderbook) ant the Size's Variable Pool (Aave v3 fork) depend on the ETH/USDC rate, it may be appropriate to use a single contract interfacing with Chainlink aggregators, as different error handling and LINK funding may cause issues once these two interconected systems are deployed.

A solution is proposed to use Size's Variable Pool (Aave v3 fork) `AaveOracle` contract directly, and simply converting the returned price to 18 decimals as the `Size` contract expects. One drawback of using `AaveOracle` is that it does not perform stale price checks for the oracle response, as it simply executes [`latestAnswer()`](https://github.com/aave/aave-v3-core/blob/6070e82d962d9b12835c88e68210d0e63f08d035/contracts/misc/AaveOracle.sol#L109) instead of `latestRoundData()`. We will update AaveOracle on our fork to also check for stale data.

##### Market Borrow Rate Feed

In order to set the current market average value of USDC variable borrow rates, we perform an off-chain calculation with Aave, convert it to 18 decimals, and store it on the oracle. For example, a rate of 2.49% on Aave v3 is represented as 24900000000000000.

Note that this rate is extracted from Aave v3 itself, not from Size's Variable Pool (Aave v3 fork). Although these two pools share the same code and interfaces, we believe Aave v3 is a better proxy for the real market rate, and less prone to market manipulation attacks.

In the future, integrations with other protocols will be implemented in order to have a more realistic global average.

## Test

```bash
forge install
forge test
```

## Coverage

<!-- BEGIN_COVERAGE -->
### FIles

| File                                                     | % Lines            | % Statements       | % Branches       | % Funcs          |
|----------------------------------------------------------|--------------------|--------------------|------------------|------------------|
| src/Size.sol                                             | 96.77% (60/62)     | 96.77% (60/62)     | 100.00% (0/0)    | 90.91% (20/22)   |
| src/SizeView.sol                                         | 46.51% (20/43)     | 51.32% (39/76)     | 0.00% (0/8)      | 79.17% (19/24)   |
| src/libraries/CapERC20Library.sol                        | 0.00% (0/4)        | 0.00% (0/4)        | 100.00% (0/0)    | 0.00% (0/2)      |
| src/libraries/ConversionLibrary.sol                      | 33.33% (1/3)       | 37.50% (3/8)       | 100.00% (0/0)    | 33.33% (1/3)     |
| src/libraries/Math.sol                                   | 86.96% (20/23)     | 87.18% (34/39)     | 83.33% (5/6)     | 83.33% (10/12)   |
| src/libraries/fixed/AccountingLibrary.sol                | 100.00% (34/34)    | 100.00% (40/40)    | 100.00% (2/2)    | 85.71% (6/7)     |
| src/libraries/fixed/CapsLibrary.sol                      | 100.00% (10/10)    | 100.00% (15/15)    | 62.50% (5/8)     | 100.00% (4/4)    |
| src/libraries/fixed/CollateralLibrary.sol                | 100.00% (6/6)      | 100.00% (8/8)      | 100.00% (0/0)    | 100.00% (2/2)    |
| src/libraries/fixed/LoanLibrary.sol                      | 95.12% (39/41)     | 95.31% (61/64)     | 93.75% (15/16)   | 92.86% (13/14)   |
| src/libraries/fixed/OfferLibrary.sol                     | 0.00% (0/4)        | 0.00% (0/12)       | 100.00% (0/0)    | 0.00% (0/4)      |
| src/libraries/fixed/RiskLibrary.sol                      | 91.67% (22/24)     | 95.12% (39/41)     | 80.00% (8/10)    | 100.00% (8/8)    |
| src/libraries/fixed/UserLibrary.sol                      | 100.00% (16/16)    | 100.00% (22/22)    | 100.00% (4/4)    | 100.00% (2/2)    |
| src/libraries/fixed/YieldCurveLibrary.sol                | 100.00% (33/33)    | 100.00% (62/62)    | 88.89% (16/18)   | 100.00% (4/4)    |
| src/libraries/fixed/actions/BorrowAsLimitOrder.sol       | 100.00% (5/5)      | 100.00% (6/6)      | 100.00% (2/2)    | 100.00% (2/2)    |
| src/libraries/fixed/actions/BorrowAsMarketOrder.sol      | 98.33% (59/60)     | 98.59% (70/71)     | 95.83% (23/24)   | 100.00% (4/4)    |
| src/libraries/fixed/actions/BorrowerExit.sol             | 97.06% (33/34)     | 97.56% (40/41)     | 83.33% (10/12)   | 100.00% (2/2)    |
| src/libraries/fixed/actions/Claim.sol                    | 100.00% (11/11)    | 100.00% (16/16)    | 100.00% (4/4)    | 100.00% (2/2)    |
| src/libraries/fixed/actions/Compensate.sol               | 100.00% (35/35)    | 100.00% (39/39)    | 100.00% (14/14)  | 100.00% (2/2)    |
| src/libraries/fixed/actions/LendAsLimitOrder.sol         | 90.00% (9/10)      | 90.00% (9/10)      | 83.33% (5/6)     | 100.00% (2/2)    |
| src/libraries/fixed/actions/LendAsMarketOrder.sol        | 100.00% (30/30)    | 100.00% (33/33)    | 92.86% (13/14)   | 100.00% (2/2)    |
| src/libraries/fixed/actions/Liquidate.sol                | 97.44% (38/39)     | 97.87% (46/47)     | 71.43% (10/14)   | 100.00% (5/5)    |
| src/libraries/fixed/actions/LiquidateWithReplacement.sol | 91.18% (31/34)     | 92.86% (39/42)     | 70.00% (7/10)    | 100.00% (3/3)    |
| src/libraries/fixed/actions/Repay.sol                    | 100.00% (15/15)    | 100.00% (19/19)    | 83.33% (5/6)     | 100.00% (2/2)    |
| src/libraries/fixed/actions/SelfLiquidate.sol            | 100.00% (21/21)    | 100.00% (27/27)    | 83.33% (5/6)     | 100.00% (2/2)    |
| src/libraries/general/actions/Deposit.sol                | 91.67% (11/12)     | 95.00% (19/20)     | 75.00% (6/8)     | 100.00% (2/2)    |
| src/libraries/general/actions/Initialize.sol             | 98.59% (70/71)     | 98.73% (78/79)     | 96.88% (31/32)   | 100.00% (11/11)  |
| src/libraries/general/actions/UpdateConfig.sol           | 86.05% (37/43)     | 85.11% (40/47)     | 85.29% (29/34)   | 66.67% (4/6)     |
| src/libraries/general/actions/Withdraw.sol               | 100.00% (17/17)    | 100.00% (24/24)    | 75.00% (9/12)    | 100.00% (2/2)    |
| src/libraries/variable/VariableLibrary.sol               | 98.65% (73/74)     | 99.03% (102/103)   | 75.00% (6/8)     | 100.00% (10/10)  |
| src/libraries/variable/actions/BorrowVariable.sol        | 100.00% (6/6)      | 100.00% (7/7)      | 100.00% (4/4)    | 100.00% (2/2)    |
| src/libraries/variable/actions/LiquidateVariable.sol     | 100.00% (6/6)      | 100.00% (7/7)      | 100.00% (4/4)    | 100.00% (2/2)    |
| src/libraries/variable/actions/RepayVariable.sol         | 100.00% (4/4)      | 100.00% (4/4)      | 100.00% (2/2)    | 100.00% (2/2)    |
| src/oracle/MarketBorrowRateFeed.sol                      | 100.00% (10/10)    | 100.00% (11/11)    | 100.00% (2/2)    | 100.00% (3/3)    |
| src/oracle/VariablePoolPriceFeed.sol                     | 100.00% (8/8)      | 100.00% (13/13)    | 100.00% (4/4)    | 100.00% (2/2)    |
| src/proxy/Vault.sol                                      | 100.00% (20/20)    | 100.00% (25/25)    | 100.00% (8/8)    | 100.00% (4/4)    |
| src/token/NonTransferrableToken.sol                      | 100.00% (9/9)      | 100.00% (10/10)    | 100.00% (0/0)    | 100.00% (7/7)    |

### Scenarios

```markdown
┌──────────────────────────┬────────┐
│         (index)          │ Values │
├──────────────────────────┼────────┤
│    BorrowAsLimitOrder    │   4    │
│   BorrowAsMarketOrder    │   13   │
│      BorrowVariable      │   2    │
│       BorrowerExit       │   6    │
│          Claim           │   9    │
│        Compensate        │   6    │
│    ConversionLibrary     │   7    │
│     CryticToFoundry      │   1    │
│         Deposit          │   3    │
│       Experiments        │   13   │
│        Initialize        │   4    │
│     LendAsLimitOrder     │   3    │
│    LendAsMarketOrder     │   6    │
│    LiquidateVariable     │   2    │
│ LiquidateWithReplacement │   5    │
│        Liquidate         │   9    │
│   MarketBorrowRateFeed   │   2    │
│           Math           │   9    │
│        Multicall         │   3    │
│  NonTransferrableToken   │   7    │
│          Pause           │   2    │
│        PriceFeed         │   1    │
│      RepayVariable       │   2    │
│          Repay           │   4    │
│    SelfLiquidateLoan     │   3    │
│      SelfLiquidate       │   6    │
│       UpdateConfig       │   4    │
│         Upgrade          │   2    │
│  VariablePoolPriceFeed   │   8    │
│          Vault           │   4    │
│         Withdraw         │   8    │
│        YieldCurve        │   13   │
└──────────────────────────┴────────┘
```
<!-- END_COVERAGE -->

## Protocol invariants

### Invariants implemented

- Check [`Properties.sol`](./test/invariants/Properties.sol)

### Invariants pending implementation

- Taking a loan with only receivables does not decrease the borrower CR
- Taking a collateralized loan decreases the borrower CR
- The user cannot withdraw more than their deposits
- If the loan is liquidatable, the liquidation should not revert
- When a user self liquidates a CreditPosition, it will improve the collateralization ratio of other CreditPosition. This is because self liquidating decreases the DebtPosition's faceValue, so it decreases all CreditPosition's assigned collateral

## Known limitations

- The protocol does not support rebasing tokens
- The protocol does not support fee-on-transfer tokens
- The protocol does not support tokens with more than 18 decimals
- The protocol only supports tokens compliant with the IERC20Metadata interface
- The protocol only supports pre-vetted tokens
- The protocol owner, KEEPER_ROLE, and PAUSER_ROLE are trusted
- The protocol does not have any fallback oracles.
- Price feeds must be redeployed and updated in case any Chainlink configuration changes (stale price timeouts, decimals)
- In case Chainlink reports a wrong price, the protocol state cannot be guaranteed. This may cause incorrect liquidations, among other issues
- In case the protocol is paused, the price of the collateral may change during the unpause event. This may cause unforseen liquidations, among other issues
- The Variable Pool Price Feed depends on `AaveOracle`, which uses `latestAnswer`, and does not perform any kind of stale checks for oracle prices
- Variable rate loans can increase the total supply of aszUSDC, which in turn limits the cap of fixed rate loans
- Users blocklisted by underlying tokens (e.g. USDC) may be unable to withdraw or interact with the protocol
- All issues acknowledged on previous audits

## Deployment

```bash
source .env
CHAIN_NAME=$CHAIN_NAME DEPLOYER_ADDRESS=$DEPLOYER_ADDRESS yarn deploy --broadcast
```
