Group 4: complete reports and equity CSVs for all three strategies on the
supplied five-day SPY file, starting with $10,000.00. Expected values are
derived by hand in docs/PROCESS.md.

  $ ../bin/main.exe ../data/small-spy-5days.csv cash equity_cash.csv --cash 10000.00
  Strategy: cash
  Period: 2008-09-15 to 2008-09-19
  Initial cash: $10000.00
  Final cash: $10000.00
  Final holdings: none
  Final portfolio value: $10000.00
  Total return: 0.00%

  $ cat equity_cash.csv
  date,value
  2008-09-15,10000.00
  2008-09-16,10000.00
  2008-09-17,10000.00
  2008-09-18,10000.00
  2008-09-19,10000.00

  $ ../bin/main.exe ../data/small-spy-5days.csv buy-and-hold equity_bh.csv --cash 10000.00 --hold SPY
  Strategy: buy-and-hold
  Period: 2008-09-15 to 2008-09-19
  Initial cash: $10000.00
  Final cash: $62.05
  Final holdings:
    SPY: 95 shares
  Final portfolio value: $10333.45
  Total return: 3.33%

  $ cat equity_bh.csv
  date,value
  2008-09-15,10000.00
  2008-09-16,10165.30
  2008-09-17,9712.15
  2008-09-18,9998.10
  2008-09-19,10333.45

  $ ../bin/main.exe ../data/small-spy-5days.csv momentum equity_mom.csv --cash 10000.00
  Strategy: momentum
  Period: 2008-09-15 to 2008-09-19
  Initial cash: $10000.00
  Final cash: $3.10
  Final holdings:
    SPY: 94 shares
  Final portfolio value: $10166.38
  Total return: 1.66%

  $ cat equity_mom.csv
  date,value
  2008-09-15,10000.00
  2008-09-16,10000.00
  2008-09-17,9551.62
  2008-09-18,9834.56
  2008-09-19,10166.38

Command-line errors (R1.2, R5.2): each prints a helpful message and exits with
status 1 instead of raising an uncaught exception.

  $ ../bin/main.exe ../data/small-spy-5days.csv buy-and-hold out.csv --cash 10000.00
  Error: Strategy 'buy-and-hold' requires --hold SYMBOL option
  Usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  [1]

  $ ../bin/main.exe ../data/small-spy-5days.csv buy-and-hold out.csv --cash 10000.00 --hold QQQ
  Error: Unknown security "QQQ" for --hold (not found in ../data/small-spy-5days.csv)
  Usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  [1]

  $ ../bin/main.exe ../data/small-spy-5days.csv random out.csv --cash 10000.00
  Error: Unknown strategy "random" (expected one of: cash, buy-and-hold, momentum)
  Usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  [1]

  $ ../bin/main.exe ../data/small-spy-5days.csv cash out.csv --cash 10000
  Error: Invalid dollar amount "10000" (expected positive DOLLARS.CC)
  Usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  [1]

  $ ../bin/main.exe ../data/small-spy-5days.csv cash out.csv --cash -100.00
  Error: Invalid dollar amount "-100.00" (expected positive DOLLARS.CC)
  Usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  [1]

  $ ../bin/main.exe ../data/small-spy-5days.csv cash out.csv --cash 0.00
  Error: Amount must be positive: 0.00
  Usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  [1]

  $ ../bin/main.exe ../data/small-spy-5days.csv cash out.csv --cash 10000.00 --bogus 1
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: option '--bogus': no such option
  [1]

  $ ../bin/main.exe ../data/small-spy-5days.csv cash out.csv
  Error: Missing required option --cash DOLLARS
  Usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  [1]

  $ ../bin/main.exe ../data/small-spy-5days.csv cash --cash 10000.00
  Error: Expected exactly 3 positional arguments (MARKET.csv STRATEGY EQUITY.csv) but got 2
  Usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  [1]

  $ ../bin/main.exe ../data/no-such-file.csv cash out.csv --cash 10000.00
  Error: Cannot open market file: ../data/no-such-file.csv: No such file or directory
  [1]

  $ ../bin/main.exe ../data/small-spy-5days.csv cash missing-dir/out.csv --cash 10000.00
  Error: Cannot write equity CSV: missing-dir/out.csv: No such file or directory
  [1]

None of the failed runs wrote an equity CSV.

  $ test -e out.csv
  [1]
