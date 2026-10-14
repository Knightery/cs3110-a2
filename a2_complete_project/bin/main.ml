open BatOptParse
open A2

let fail_cli (msg : string) : 'a =
  Printf.eprintf "Error: %s\n" msg;
  exit 1

let resolve_strategy (name : string) : (module Strategy.S) =
  match name with
  | "cash" -> (module Cash_strategy)
  | "buy-and-hold" -> (module Buy_and_hold_strategy)
  | "momentum" -> (module Momentum_strategy)
  | _ ->
      fail_cli
        (Printf.sprintf
           "Unknown strategy %S (expected 'cash', 'buy-and-hold', or \
            'momentum')"
           name)

let parse_args () : string * string * string * int * string option =
  let cash_opt = StdOpt.str_option () in
  let hold_opt = StdOpt.str_option () in
  let parser =
    OptParser.make
      ~usage:
        "%prog MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]"
      ()
  in
  OptParser.add parser ~long_name:"cash"
    ~help:"Initial cash in positive DOLLARS.CC format" cash_opt;
  OptParser.add parser ~long_name:"hold"
    ~help:"Security symbol to hold for buy-and-hold strategy" hold_opt;
  let pos_args =
    try OptParser.parse_argv parser
    with exn -> fail_cli (Printexc.to_string exn)
  in
  match pos_args with
  | [ market_file; strategy_name; equity_file ] ->
      let initial_cash =
        match Opt.opt cash_opt with
        | None -> fail_cli "Missing required option --cash DOLLARS"
        | Some cash_str -> (
            match Market.parse_cents cash_str with
            | Ok cents -> cents
            | Error msg -> fail_cli msg)
      in
      let hold_symbol = Opt.opt hold_opt in
      (market_file, strategy_name, equity_file, initial_cash, hold_symbol)
  | _ ->
      fail_cli
        "Expected exactly 3 positional arguments: MARKET.csv STRATEGY \
         EQUITY.csv"

let () =
  let market_file, strategy_name, equity_file, initial_cash, hold_symbol =
    parse_args ()
  in
  let strat_mod = resolve_strategy strategy_name in
  let market =
    match Market.load market_file with Ok m -> m | Error msg -> fail_cli msg
  in
  (if strategy_name = "buy-and-hold" then
     match hold_symbol with
     | None -> fail_cli "Strategy 'buy-and-hold' requires --hold SYMBOL option"
     | Some sym ->
         if not (List.mem sym market.securities) then
           fail_cli
             (Printf.sprintf "Unknown security %S for --hold (not found in %s)"
                sym market_file));
  let result = Engine.run strat_mod ?hold_symbol ~initial_cash market in
  match Report.write_equity_csv equity_file result with
  | Error msg -> fail_cli msg
  | Ok () -> print_endline (Report.format_summary result)
