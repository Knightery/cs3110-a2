# A2 Market Data

The historical CSV files in this directory were created from the public domain [Huge
Stock Market Dataset][hsmd] (HSMD).

- `handout.csv` is the tiny fictional price dataset shown in the handout.

- `small-spy-5days.csv` is a small historical price dataset: five consecutive trading
  dates of the SPY during the Lehman-collapse week (September 15–19, 2008). SPY
  is an exchange-traded fund that intends to correspond generally to the price
  and yield performance of the S&P 500 Index.

- `medium-tech-2007.csv` is a medium historical price dataset: the 251 shared trading dates in
  calendar year 2007 for AAPL, AMZN, CSCO, INTC, and MSFT. It provides the year
  immediately before the 2008 financial crisis.

- `large-dotcom-ca2000.csv` is a large historical price dataset: 748 shared trading
  dates from 1999 through 2001 for 20 companies. It includes technology
  companies (AAPL, AMZN, CSCO, HPQ, INTC, MSFT, and ORCL), health care,
  consumer, energy, finance, and industrial companies, so the dot-com collapse
  does not determine every security's result.

[hsmd]: https://www.kaggle.com/datasets/borismarjanovic/price-volume-data-for-all-us-stocks-etfs

## Market files created for this project's tests

- `custom.csv` is a tiny fictional file with new securities (APEX, BOLT, CRUX)
  over five dates. With $100.00, buy-and-hold APEX leaves $10.00 unspent while
  APEX's price changes; momentum hits a tie broken by column order, re-selects
  its current target, sees a day with no positive increase, and rotates targets
  using sale proceeds.

- `edge-cases.csv` is a tiny fictional file with a cheap security (KILN) and an
  expensive one (OPAL) over seven dates. With $100.00, buy-and-hold OPAL cannot
  afford a share on the first date and must stay in cash even after OPAL becomes
  affordable. Momentum selects OPAL when it cannot afford a share, must still
  remember it as the target, and must make no orders when OPAL is re-selected
  later, even though a share is then affordable.

`docs/PROCESS.md` gives the hand-calculated expected state for every date.
