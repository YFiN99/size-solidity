# size-v2-solidity

Size V2 Solidity

## Setup

Install <https://github.com/0xClandestine/solplot>

## Invariants

| Property | Category    | Description                                                                              |
| -------- | ----------- | ---------------------------------------------------------------------------------------- |
| C-01     | Collateral  | Locked cash in the user account can't be withdrawn                                       |
| C-02     | Collateral  | The sum of all free and locked collateral is equal to the token balance of the orderbook |
| L-01     | Liquidation | A borrower is eligible to liquidation if it is underwater or if the due date has reached |

References

- <https://hackmd.io/lWCjLs9NSiORaEzaWRJdsQ?view>
