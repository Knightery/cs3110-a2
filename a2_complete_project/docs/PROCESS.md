# A2: Past Performance — Development Process & Validation Record

## Part 1: End-to-End Development Tasks (R0.1, R0.2)

### Task 1: End-to-End Cash Simulation & Dated Value Recording
- **Observable Executable Behavior:** Read a valid market CSV file (`data/handout.csv`), pass each trading date's row sequentially through the simulation engine using the `cash` strategy with `$100.00` initial cash, write the `date,value` equity CSV, and print the final summary report showing unchanged cash and portfolio value (`$100.00`) on every date.
- **Planned Test:** Run OUnit test `test_cash_handout` and CLI command `dune exec bin/main.exe -- data/handout.csv cash equity.csv --cash 100.00` and verify that each of the three dates (`2024-01-02`, `2024-01-03`, `2024-01-04`) has `cash = 10000` cents, `holdings = []`, and `value = 10000` cents, with `0.00%` total return.
- **Actual Result (2026-10-14):** `dune test` passed, including `test_cash_handout`, which checks cash, holdings, and value on all three dates. I also ran `dune exec bin/main.exe -- data/handout.csv cash equity.csv --cash 100.00` and inspected `equity.csv` with `cat equity.csv`. The summary showed final cash `$100.00`, final value `$100.00`, and return `0.00%`. The CSV had exactly the header `date,value` and rows `2024-01-02,100.00`, `2024-01-03,100.00`, and `2024-01-04,100.00`.

### Task 2: Portfolio Order Accounting & Buy-and-Hold Execution
- **Observable Executable Behavior:** Execute the `buy-and-hold` strategy (`--hold SYMBOL`) through the same engine and strategy interface (`Strategy.S`), purchasing as many whole shares as possible on the first date, leaving any remainder in cash, rejecting invalid orders without halting later valid orders, and revaluing the held shares at each date's closing price.
- **Planned Test:**
  1. Run OUnit test `test_portfolio_order_rejection_and_sequence` with a sequence of rejected orders (zero/negative quantity, unknown security, insufficient cash, insufficient shares) followed by valid buy/sell/buy orders.
  2. Run `buy-and-hold` on `data/handout.csv` (`--hold ALFA`, `$100.00`) and `data/custom.csv` (`--hold APEX`, `$100.00`) and verify daily cash, holdings, and portfolio value.
- **Actual Result (2026-10-14):** `dune test` passed. The two buy-and-hold OUnit tests checked every dated cash balance, holding, and value against the independently calculated states below. The order-sequence test passed: five invalid orders were ignored, and three later valid orders resulted in cash `500` cents, `2` ALFA shares, `3` BETA shares, and value `10000` cents. I also ran buy-and-hold on `data/handout.csv` using `--hold ALFA`, inspected its complete final report and `equity-hold.csv`, and confirmed final cash `$0.00`, 10 ALFA shares, value `$110.00`, return `10.00%`, and dated values `$100.00`, `$120.00`, `$110.00`.

### Task 3: Stateful One-Day Momentum Strategy Behind Shared Interface
- **Observable Executable Behavior:** Run `momentum` through `Engine.run (module Momentum_strategy)` sealed under `Strategy.S` with an abstract `state` type, where each date's `step` receives only that date's price row and current portfolio, selects the security with the largest strictly positive 1-day increase (breaking ties in column order), sells existing holdings first when switching targets, and uses sale proceeds plus existing cash to buy whole shares of the new target.
- **Planned Test:** Run OUnit tests `test_momentum_handout` (on `data/handout.csv`) and `test_momentum_custom` (on `data/custom.csv`, exercising tie-breaking, target retention on repeat winner, target retention on non-positive changes, and target rotation using sale proceeds).
- **Actual Result (2026-10-14):** `dune test` passed both momentum OUnit tests. Their assertions check each dated cash balance, holding, and value, including the tie, unchanged target, no-positive-change day, and sell-then-buy transition on `custom.csv`. I also ran momentum on `data/handout.csv`, inspected its complete report and `equity-momentum.csv`, and confirmed final cash `$8.00`, 4 BETA shares, value `$92.00`, return `-8.00%`, and dated values `$100.00`, `$100.00`, `$92.00`.

### Task 4: Command-Line Reports and Error Handling
- **Observable executable behavior:** Parse the required arguments using `BatOptParse`, run the selected strategy, write an equity CSV, and print the complete final summary. For invalid arguments or an unreadable market file, print a helpful error message and exit unsuccessfully rather than exposing an exception.
- **Planned tests:**
  1. Run the three Cram commands in `test/cram.t` for `cash`, `buy-and-hold`, and `momentum` on `data/small-spy-5days.csv`, all starting with `$10,000.00`, and compare the **entire standard output** with hand-calculated reports.
  2. Manually try a missing `--cash`, an unknown strategy, a missing `--hold` for `buy-and-hold`, an unknown holding symbol, and a nonexistent input file; check error messages and nonzero exit codes.
  3. Inspect an equity CSV to confirm the header is exactly `date,value` and there is one correctly formatted value per input date.
- **Actual result (2026-10-14):** After correcting `test/cram.t`, I ran `dune test && echo "ALL TESTS PASSED"`, which printed `ALL TESTS PASSED`. This includes the three Cram comparisons of complete stdout reports. Final values were `$10000.00` (cash), `$10333.45` (buy-and-hold), and `$10166.38` (momentum), agreeing with the independent calculations below. Manual checks of each strategy's report and dated equity CSV on `data/handout.csv` also matched the expected results.

  I verified four invalid invocations: missing `--hold` for `buy-and-hold` printed `Error: Strategy 'buy-and-hold' requires --hold SYMBOL option`; `--cash -100.00` printed `Error: Invalid dollar amount "-100.00" (expected positive DOLLARS.CC)`; an unknown strategy `random` printed `Error: Unknown strategy "random" (expected 'cash', 'buy-and-hold', or 'momentum')`; and a nonexistent market file printed a `Cannot open market file` error. **All four exited with status `1`**, with no uncaught exception. Additional possible bad invocations, such as an unknown `--hold` symbol, were not part of these manual checks.

### Consequential revision during development
- **Correcting the Cram validation file (2026-10-14):** The original `test/cram.t` gave `2017-11-06` through `2017-11-10` as the cash-run dates, but the supplied `data/small-spy-5days.csv` actually covers `2008-09-15` through `2008-09-19`. The buy-and-hold and momentum commands also lacked expected report lines. We inspected the CSV, independently calculated all three summaries, and updated the Cram expectations to cover the complete output. The revised suite then passed with `dune test` on 2026-10-14.

### Design choices relevant to validation
- `Strategy.S` accepts an optional hold symbol in `init`, allowing all strategies to use the same engine interface without calling strategy-specific helpers.
- `Market.row.prices` stores `(security * int) list` in market-file column order, so momentum tie-breaking uses the required original order rather than the sorted order of a map.

### Local verification record (2026-10-14)
- `dune build` completed successfully without diagnostic output.
- `dune test && echo "ALL TESTS PASSED"` printed `ALL TESTS PASSED`; the six OUnit scenarios and three complete-report Cram scenarios are included in the automated suite.
- Manual `cash` run: complete summary and `equity.csv` matched three expected values of `$100.00`.
- Manual `buy-and-hold --hold ALFA` run: complete summary matched `$0.00` cash, 10 ALFA shares, `$110.00` final value, and `10.00%` return; `equity-hold.csv` had `$100.00`, `$120.00`, `$110.00`.
- Manual `momentum` run: complete summary matched `$8.00` cash, 4 BETA shares, `$92.00` final value, and `-8.00%` return; `equity-momentum.csv` had `$100.00`, `$100.00`, `$92.00`.
- The four manually tested error cases (missing `--hold`, negative `--cash`, unknown strategy, nonexistent market file) each reported a helpful error and exited with status `1`.
- These observations establish that the tested executable paths and outputs match their predictions; they do not constitute exhaustive testing of every possible input.

---

## Part 2: Independent Validation Argument & Expected Results (R7.3)

### Group 1: Cash Strategy on `data/handout.csv` (`$100.00` = `10000` cents)
- **Independent Calculation:** The `cash` strategy proposes no orders (`[]`) on any date.
  - `2024-01-02`: `cash = 10000` (`$100.00`), `holdings = []`, `value = 10000` (`$100.00`).
  - `2024-01-03`: `cash = 10000` (`$100.00`), `holdings = []`, `value = 10000` (`$100.00`).
  - `2024-01-04`: `cash = 10000` (`$100.00`), `holdings = []`, `value = 10000` (`$100.00`).
  - **Final Summary:** Cash `$100.00`, Holdings none, Final Value `$100.00`, Total Return `0.00%`.

### Group 2: Buy-and-Hold Strategy (`$100.00` = `10000` cents)
1. **On `data/handout.csv` holding `ALFA`:**
   - `2024-01-02` (`ALFA = 1000`, `BETA = 2500`): Buys `10000 / 1000 = 10` shares of `ALFA` for `10000` cents. `cash = 0`, `holdings = [("ALFA", 10)]`, `value = 0 + 10 * 1000 = 10000` (`$100.00`).
   - `2024-01-03` (`ALFA = 1200`, `BETA = 2000`): No orders. `cash = 0`, `holdings = [("ALFA", 10)]`, `value = 10 * 1200 = 12000` (`$120.00`).
   - `2024-01-04` (`ALFA = 1100`, `BETA = 2100`): No orders. `cash = 0`, `holdings = [("ALFA", 10)]`, `value = 10 * 1100 = 11000` (`$110.00`).
   - **Final Summary:** Cash `$0.00`, Holdings `ALFA: 10 shares`, Final Value `$110.00`, Total Return `10.00%`.
2. **On `data/custom.csv` holding `APEX`:**
   - **How `data/custom.csv` exercises `buy-and-hold`:** Uses three new securities (`APEX`, `BOLT`, `CRUX`) over 5 trading dates (`2024-02-01` to `2024-02-07`). On day 1, `APEX` costs `$15.00` (`1500` cents), which does not divide `$100.00` (`10000` cents) evenly—leaving `$10.00` (`1000` cents) in unspent cash while `APEX` fluctuates across subsequent dates (`15.00 -> 18.00 -> 20.00 -> 19.00 -> 20.00`).
   - `2024-02-01` (`APEX = 1500`): Buys `10000 / 1500 = 6` shares (`9000` cents). `cash = 1000` (`$10.00`), `holdings = [("APEX", 6)]`, `value = 1000 + 6 * 1500 = 10000` (`$100.00`).
   - `2024-02-02` (`APEX = 1800`): `cash = 1000`, `holdings = [("APEX", 6)]`, `value = 1000 + 6 * 1800 = 11800` (`$118.00`).
   - `2024-02-05` (`APEX = 2000`): `cash = 1000`, `holdings = [("APEX", 6)]`, `value = 1000 + 6 * 2000 = 13000` (`$130.00`).
   - `2024-02-06` (`APEX = 1900`): `cash = 1000`, `holdings = [("APEX", 6)]`, `value = 1000 + 6 * 1900 = 12400` (`$124.00`).
   - `2024-02-07` (`APEX = 2000`): `cash = 1000`, `holdings = [("APEX", 6)]`, `value = 1000 + 6 * 2000 = 13000` (`$130.00`).
   - **Final Summary:** Cash `$10.00`, Holdings `APEX: 6 shares`, Final Value `$130.00`, Total Return `30.00%`.

### Group 3: Stateful (`momentum`) Strategy (`$100.00` = `10000` cents)
1. **On `data/handout.csv`:**
   - `2024-01-02` (`ALFA = 1000`, `BETA = 2500`): First date; remembers prices, sets `target = None`, makes no orders. `cash = 10000`, `holdings = []`, `value = 10000` (`$100.00`).
   - `2024-01-03` (`ALFA = 1200`, `BETA = 2000`): Changes are `ALFA: +200`, `BETA: -500`. Largest positive increase is `ALFA` (`+200`). Target changes from `None` to `Some "ALFA"`. Buys `10000 / 1200 = 8` shares of `ALFA` (`9600` cents). `cash = 400` (`$4.00`), `holdings = [("ALFA", 8)]`, `value = 400 + 8 * 1200 = 10000` (`$100.00`).
   - `2024-01-04` (`ALFA = 1100`, `BETA = 2100`): Changes are `ALFA: -100`, `BETA: +100`. Largest positive increase is `BETA` (`+100`). Target changes from `Some "ALFA"` to `Some "BETA"`. Sells 8 `ALFA` at `1100` (`+8800` cents -> `9200` cents available cash), then buys `9200 / 2100 = 4` shares of `BETA` (`8400` cents). `cash = 800` (`$8.00`), `holdings = [("BETA", 4)]`, `value = 800 + 4 * 2100 = 9200` (`$92.00`).
   - **Final Summary:** Cash `$8.00`, Holdings `BETA: 4 shares`, Final Value `$92.00`, Total Return `-8.00%`.
2. **On `data/custom.csv`:**
   - **How `data/custom.csv` exercises `momentum`:** Specifically designed to test all four stateful transition branches of one-day momentum:
     - **Day 1 (`2024-02-01`, `APEX=15.00, BOLT=20.00, CRUX=10.00`):** Initialization (`target = None`, no orders). `cash = 10000`, `holdings = []`, `value = 10000`.
     - **Day 2 (`2024-02-02`, `APEX=18.00, BOLT=23.00, CRUX=11.00`) — Tie-breaking in market-file column order:** `APEX` (`+300`) and `BOLT` (`+300`) tie for the largest strictly positive increase (`CRUX` is `+100`). Because `APEX` appears before `BOLT` in the header, `APEX` is selected. Buys `10000 / 1800 = 5` shares of `APEX` (`9000` cents). `cash = 1000`, `holdings = [("APEX", 5)]`, `value = 10000`, `target = Some "APEX"`.
     - **Day 3 (`2024-02-05`, `APEX=20.00, BOLT=24.00, CRUX=9.00`) — Same target selected again:** Changes are `APEX: +200`, `BOLT: +100`, `CRUX: -200`. `APEX` wins again; since `target` is already `Some "APEX"`, no orders are proposed (even though `$10.00` cash remains). `cash = 1000`, `holdings = [("APEX", 5)]`, `value = 1000 + 5 * 2000 = 11000`.
     - **Day 4 (`2024-02-06`, `APEX=19.00, BOLT=24.00, CRUX=9.00`) — No strictly positive increase:** Changes are `APEX: -100`, `BOLT: 0`, `CRUX: 0`. Since `0` is not strictly positive, no security is selected; `momentum` makes no orders and retains `target = Some "APEX"`. `cash = 1000`, `holdings = [("APEX", 5)]`, `value = 1000 + 5 * 1900 = 10500`.
     - **Day 5 (`2024-02-07`, `APEX=20.00, BOLT=22.00, CRUX=12.00`) — Target switch & sequential sell-then-buy:** Changes are `APEX: +100`, `BOLT: -200`, `CRUX: +300`. `CRUX` wins (`+300`). Target switches from `Some "APEX"` to `Some "CRUX"`. First sells 5 shares of `APEX` at `2000` (`+10000` cents -> `11000` total cash), then buys `11000 / 1200 = 9` shares of `CRUX` (`10800` cents). `cash = 200`, `holdings = [("CRUX", 9)]`, `value = 200 + 9 * 1200 = 11000`.
     - **Final Summary:** Cash `$2.00`, Holdings `CRUX: 9 shares`, Final Value `$110.00`, Total Return `10.00%`.

### Group 4: Command-Line Reports (Cram on `data/small-spy-5days.csv` with `$10,000.00`)
The supplied five SPY closing prices are `$104.61`, `$106.35`, `$101.58`, `$104.59`, and `$108.12`, dated `2008-09-15` through `2008-09-19`.

- **Cash:** Makes no trades; final cash and value remain `$10000.00`, with no holdings and `0.00%` total return. The expected equity CSV value is `$10000.00` on every one of the five dates.
- **Buy-and-hold:** On the first date, buys `floor(1000000 / 10461) = 95` SPY shares, spending `993795` cents and leaving `6205` cents (`$62.05`). At the last price, final value is `6205 + 95 * 10812 = 1033345` cents (`$10333.45`) for a rounded `3.33%` total return. The independently calculated dated equity values, in dollars, are `$10000.00`, `$10165.30`, `$9712.15`, `$9998.10`, and `$10333.45`.
- **Momentum:** On the first date makes no trade. The SPY price increases on the second date, so it buys `floor(1000000 / 10635) = 94` shares for `999690` cents, leaving `310` cents (`$3.10`). Because there is only one security, later increases select the same target and declines cause no orders. Its last value is `310 + 94 * 10812 = 1016638` cents (`$10166.38`), a rounded `1.66%` return. The independently calculated dated equity values are `$10000.00`, `$10000.00`, `$9551.62`, `$9834.56`, and `$10166.38`.
- **Cram coverage:** `test/cram.t` contains all three commands and their complete expected standard-output summaries, including strategy name, correct date range, initial/final cash, final holdings, final portfolio value, and total return. **These predictions were calculated from the supplied CSV, and the revised Cram suite passed locally on 2026-10-14.**
