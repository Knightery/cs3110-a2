open BatOptParse
open A2

let usage = "MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]"

(* [fail msg] reports a runtime error, such as an unreadable file. *)
let fail (msg : string) : 'a =
  Printf.eprintf "Error: %s\n" msg;
  exit 1

(* [fail_cli msg] reports an invalid command line, followed by a usage line. *)
let fail_cli (msg : string) : 'a =
  Printf.eprintf "Error: %s\nUsage: %s %s\n" msg
    (Filename.basename Sys.executable_name)
    usage;
  exit 1

(* Every available strategy. Adding a strategy means adding its module here;
   the engine and the rest of this file need no changes. *)
let strategies : (module Strategy.S) list =
  [
    (module Cash_strategy);
    (module Buy_and_hold_strategy);
    (module Momentum_strategy);
  ]

let strategy_name (module S : Strategy.S) : string = S.name

let resolve_strategy (name : string) : (module Strategy.S) =
  match List.find_opt (fun s -> strategy_name s = name) strategies with
  | Some s -> s
  | None ->
      fail_cli
        (Printf.sprintf "Unknown strategy %S (expected one of: %s)" name
           (String.concat ", " (List.map strategy_name strategies)))

let parse_args () : string * string * string * int * string option =
  let cash_opt = StdOpt.str_option () in
  let hold_opt = StdOpt.str_option () in
  let parser = OptParser.make ~usage:("%prog " ^ usage) () in
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
  | args ->
      fail_cli
        (Printf.sprintf
           "Expected exactly 3 positional arguments (MARKET.csv STRATEGY \
            EQUITY.csv) but got %d"
           (List.length args))

let () =
  let market_file, strategy_name, equity_file, initial_cash, hold_symbol =
    parse_args ()
  in
  let strat_mod = resolve_strategy strategy_name in
  let market =
    match Market.load market_file with Ok m -> m | Error msg -> fail msg
  in
  (* The --hold symbol can only be validated against the market file's header,
     so this check happens after loading the market. *)
  (if strategy_name = Buy_and_hold_strategy.name then
     match hold_symbol with
     | None -> fail_cli "Strategy 'buy-and-hold' requires --hold SYMBOL option"
     | Some sym ->
         if not (List.mem sym market.securities) then
           fail_cli
             (Printf.sprintf "Unknown security %S for --hold (not found in %s)"
                sym market_file));
  let result = Engine.run strat_mod ?hold_symbol ~initial_cash market in
  match Report.write_equity_csv equity_file result with
  | Error msg -> fail msg
  | Ok () -> print_endline (Report.format_summary result)
