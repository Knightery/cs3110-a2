open OUnit2
open A2

let data_path (filename : string) : string =
  let p1 = Filename.concat "data" filename in
  if Sys.file_exists p1 then p1
  else Filename.concat (Filename.concat ".." "data") filename

let load_market_exn (filename : string) : Market.t =
  match Market.load (data_path filename) with
  | Ok m -> m
  | Error msg -> assert_failure ("Failed to load market file: " ^ msg)

let string_of_holdings (h : (string * int) list) : string =
  "["
  ^ String.concat "; "
      (List.map (fun (s, q) -> Printf.sprintf "(%S, %d)" s q) h)
  ^ "]"

let string_of_dated_state (st : Engine.dated_state) : string =
  Printf.sprintf "{ date = %S; cash = %d; holdings = %s; value = %d }" st.date
    st.cash
    (string_of_holdings st.holdings)
    st.value

let assert_history_equal (expected : Engine.dated_state list)
    (actual : Engine.dated_state list) : unit =
  assert_equal ~msg:"Number of dated states in history" ~printer:string_of_int
    (List.length expected) (List.length actual);
  List.iter2
    (fun exp act ->
      assert_equal
        ~msg:("Dated state on " ^ exp.Engine.date)
        ~printer:string_of_dated_state exp act)
    expected actual

(* Group 1: Cash strategy on data/handout.csv with $100.00 *)
let test_cash_handout _ =
  let market = load_market_exn "handout.csv" in
  let res = Engine.run (module Cash_strategy) ~initial_cash:10000 market in
  let expected : Engine.dated_state list =
    [
      { date = "2024-01-02"; cash = 10000; holdings = []; value = 10000 };
      { date = "2024-01-03"; cash = 10000; holdings = []; value = 10000 };
      { date = "2024-01-04"; cash = 10000; holdings = []; value = 10000 };
    ]
  in
  assert_history_equal expected res.history;
  assert_equal ~printer:string_of_int 10000 res.final_cash;
  assert_equal ~printer:string_of_holdings [] res.final_holdings;
  assert_equal ~printer:string_of_int 10000 res.final_value

(* Group 2: Buy-and-hold on data/handout.csv and data/custom.csv *)
let test_buy_and_hold_handout_alfa _ =
  let market = load_market_exn "handout.csv" in
  let res =
    Engine.run
      (module Buy_and_hold_strategy)
      ~hold_symbol:"ALFA" ~initial_cash:10000 market
  in
  let expected : Engine.dated_state list =
    [
      {
        date = "2024-01-02";
        cash = 0;
        holdings = [ ("ALFA", 10) ];
        value = 10000;
      };
      {
        date = "2024-01-03";
        cash = 0;
        holdings = [ ("ALFA", 10) ];
        value = 12000;
      };
      {
        date = "2024-01-04";
        cash = 0;
        holdings = [ ("ALFA", 10) ];
        value = 11000;
      };
    ]
  in
  assert_history_equal expected res.history;
  assert_equal ~printer:string_of_int 0 res.final_cash;
  assert_equal ~printer:string_of_holdings [ ("ALFA", 10) ] res.final_holdings;
  assert_equal ~printer:string_of_int 11000 res.final_value

let test_buy_and_hold_custom_apex _ =
  let market = load_market_exn "custom.csv" in
  let res =
    Engine.run
      (module Buy_and_hold_strategy)
      ~hold_symbol:"APEX" ~initial_cash:10000 market
  in
  let expected : Engine.dated_state list =
    [
      {
        date = "2024-02-01";
        cash = 1000;
        holdings = [ ("APEX", 6) ];
        value = 10000;
      };
      {
        date = "2024-02-02";
        cash = 1000;
        holdings = [ ("APEX", 6) ];
        value = 11800;
      };
      {
        date = "2024-02-05";
        cash = 1000;
        holdings = [ ("APEX", 6) ];
        value = 13000;
      };
      {
        date = "2024-02-06";
        cash = 1000;
        holdings = [ ("APEX", 6) ];
        value = 12400;
      };
      {
        date = "2024-02-07";
        cash = 1000;
        holdings = [ ("APEX", 6) ];
        value = 13000;
      };
    ]
  in
  assert_history_equal expected res.history;
  assert_equal ~printer:string_of_int 1000 res.final_cash;
  assert_equal ~printer:string_of_holdings [ ("APEX", 6) ] res.final_holdings;
  assert_equal ~printer:string_of_int 13000 res.final_value

(* Group 3: Momentum strategy on data/handout.csv and data/custom.csv *)
let test_momentum_handout _ =
  let market = load_market_exn "handout.csv" in
  let res = Engine.run (module Momentum_strategy) ~initial_cash:10000 market in
  let expected : Engine.dated_state list =
    [
      { date = "2024-01-02"; cash = 10000; holdings = []; value = 10000 };
      {
        date = "2024-01-03";
        cash = 400;
        holdings = [ ("ALFA", 8) ];
        value = 10000;
      };
      {
        date = "2024-01-04";
        cash = 800;
        holdings = [ ("BETA", 4) ];
        value = 9200;
      };
    ]
  in
  assert_history_equal expected res.history;
  assert_equal ~printer:string_of_int 800 res.final_cash;
  assert_equal ~printer:string_of_holdings [ ("BETA", 4) ] res.final_holdings;
  assert_equal ~printer:string_of_int 9200 res.final_value

let test_momentum_custom _ =
  let market = load_market_exn "custom.csv" in
  let res = Engine.run (module Momentum_strategy) ~initial_cash:10000 market in
  let expected : Engine.dated_state list =
    [
      { date = "2024-02-01"; cash = 10000; holdings = []; value = 10000 };
      {
        date = "2024-02-02";
        cash = 1000;
        holdings = [ ("APEX", 5) ];
        value = 10000;
      };
      {
        date = "2024-02-05";
        cash = 1000;
        holdings = [ ("APEX", 5) ];
        value = 11000;
      };
      {
        date = "2024-02-06";
        cash = 1000;
        holdings = [ ("APEX", 5) ];
        value = 10500;
      };
      {
        date = "2024-02-07";
        cash = 200;
        holdings = [ ("CRUX", 9) ];
        value = 11000;
      };
    ]
  in
  assert_history_equal expected res.history;
  assert_equal ~printer:string_of_int 200 res.final_cash;
  assert_equal ~printer:string_of_holdings [ ("CRUX", 9) ] res.final_holdings;
  assert_equal ~printer:string_of_int 11000 res.final_value

(* Group 4 (Unit): Portfolio order rejection and sequence rules *)
let test_portfolio_order_rejection_and_sequence _ =
  let row : Market.row =
    { date = "2024-01-02"; prices = [ ("ALFA", 1000); ("BETA", 2500) ] }
  in
  let p0 = Portfolio.init 10000 in
  let orders : Portfolio.order list =
    [
      (* Rejected: non-positive quantity *)
      { security = "ALFA"; direction = Buy; quantity = 0 };
      { security = "ALFA"; direction = Buy; quantity = -2 };
      (* Rejected: unknown security *)
      { security = "GAMMA"; direction = Buy; quantity = 1 };
      (* Rejected: insufficient cash (11 * 1000 = 11000 > 10000) *)
      { security = "ALFA"; direction = Buy; quantity = 11 };
      (* Rejected: insufficient shares to sell *)
      { security = "ALFA"; direction = Sell; quantity = 1 };
      (* Valid: buy 3 ALFA for 3000 cents -> cash 7000 *)
      { security = "ALFA"; direction = Buy; quantity = 3 };
      (* Valid: sell 1 ALFA for 1000 cents -> cash 8000, ALFA 2 *)
      { security = "ALFA"; direction = Sell; quantity = 1 };
      (* Valid: buy 3 BETA for 7500 cents using sale proceeds -> cash 500 *)
      { security = "BETA"; direction = Buy; quantity = 3 };
    ]
  in
  let p_final = Portfolio.apply_orders row p0 orders in
  assert_equal ~printer:string_of_int 500 (Portfolio.cash p_final);
  assert_equal ~printer:string_of_holdings
    [ ("ALFA", 2); ("BETA", 3) ]
    (Portfolio.holdings p_final);
  assert_equal ~printer:string_of_int 10000 (Portfolio.value row p_final)

(* Group 2 (continued): buy-and-hold when no share is affordable. OPAL costs
   $150.00 on the first date, so $100.00 buys nothing. OPAL later falls to
   $90.00 (2024-03-06); a strategy that kept retrying after the first date
   would wrongly buy one share then. *)
let test_buy_and_hold_edge_unaffordable _ =
  let market = load_market_exn "edge-cases.csv" in
  let res =
    Engine.run
      (module Buy_and_hold_strategy)
      ~hold_symbol:"OPAL" ~initial_cash:10000 market
  in
  let all_cash (date : string) : Engine.dated_state =
    { date; cash = 10000; holdings = []; value = 10000 }
  in
  let expected =
    List.map all_cash
      [
        "2024-03-01";
        "2024-03-04";
        "2024-03-05";
        "2024-03-06";
        "2024-03-07";
        "2024-03-08";
        "2024-03-11";
      ]
  in
  assert_history_equal expected res.history;
  assert_equal ~printer:string_of_int 10000 res.final_cash;
  assert_equal ~printer:string_of_holdings [] res.final_holdings;
  assert_equal ~printer:string_of_int 10000 res.final_value

(* Group 3 (continued): momentum on data/edge-cases.csv with $100.00. This file
   exercises the two rules that custom.csv cannot: a newly selected target that
   is unaffordable is still remembered, and re-selecting the remembered target
   makes no orders even if no shares of it were ever bought. *)
let test_momentum_edge_cases _ =
  let market = load_market_exn "edge-cases.csv" in
  let res = Engine.run (module Momentum_strategy) ~initial_cash:10000 market in
  let expected : Engine.dated_state list =
    [
      (* First date: remember prices; no orders. *)
      { date = "2024-03-01"; cash = 10000; holdings = []; value = 10000 };
      (* KILN +100 beats OPAL -100: buy 10000 / 900 = 11 KILN for 9900. *)
      {
        date = "2024-03-04";
        cash = 100;
        holdings = [ ("KILN", 11) ];
        value = 10000;
      };
      (* OPAL +600 beats KILN +50: sell 11 KILN at 950 (cash 10550), but
         10550 / 15500 = 0 OPAL shares are affordable. Target becomes OPAL. *)
      { date = "2024-03-05"; cash = 10550; holdings = []; value = 10550 };
      (* Both prices fall: no positive increase, so target stays OPAL. *)
      { date = "2024-03-06"; cash = 10550; holdings = []; value = 10550 };
      (* OPAL +500 wins and one share (9500) is now affordable, but OPAL is
         already the remembered target, so no orders. *)
      { date = "2024-03-07"; cash = 10550; holdings = []; value = 10550 };
      (* KILN +80 beats OPAL +50: switch; buy 10550 / 1000 = 10 KILN. *)
      {
        date = "2024-03-08";
        cash = 550;
        holdings = [ ("KILN", 10) ];
        value = 10550;
      };
      (* KILN wins again: no orders. Value = 550 + 10 * 1100. *)
      {
        date = "2024-03-11";
        cash = 550;
        holdings = [ ("KILN", 10) ];
        value = 11550;
      };
    ]
  in
  assert_history_equal expected res.history;
  assert_equal ~printer:string_of_int 550 res.final_cash;
  assert_equal ~printer:string_of_holdings [ ("KILN", 10) ] res.final_holdings;
  assert_equal ~printer:string_of_int 11550 res.final_value

(* Engine: what each strategy can observe (R4.2). *)

(* Rows observed by [Recording_strategy], most recent first. *)
let observed_rows : Market.row list ref = ref []

(* A test-only strategy, sealed at [Strategy.S] like the real ones, that records
   every row the engine passes to [step] and makes no orders. *)
module Recording_strategy : Strategy.S = struct
  type state = unit

  let name = "recording"
  let init (_ : string option) : state = ()

  let step (st : state) (row : Market.row) (_ : Portfolio.t) :
      state * Portfolio.order list =
    observed_rows := row :: !observed_rows;
    (st, [])
end

let string_of_rows (rows : Market.row list) : string =
  String.concat "; "
    (List.map
       (fun (r : Market.row) -> r.date ^ " " ^ string_of_holdings r.prices)
       rows)

let test_engine_passes_each_row_once_in_order _ =
  let market = load_market_exn "custom.csv" in
  observed_rows := [];
  let _ = Engine.run (module Recording_strategy) ~initial_cash:10000 market in
  assert_equal ~msg:"Rows passed to step" ~printer:string_of_rows market.rows
    (List.rev !observed_rows)

(* Changing only the final row of custom.csv must not change any earlier dated
   state, because no strategy can see a row before the engine reaches it. *)
let test_later_row_does_not_change_earlier_states _ =
  let market = load_market_exn "custom.csv" in
  let earlier, last =
    match List.rev market.rows with
    | last :: rev_earlier -> (List.rev rev_earlier, last)
    | [] -> assert_failure "custom.csv has no rows"
  in
  (* Raise BOLT on the final date from $22.00 to $99.00. *)
  let altered_last : Market.row =
    {
      last with
      prices =
        List.map
          (fun (sec, p) -> if sec = "BOLT" then (sec, 9900) else (sec, p))
          last.prices;
    }
  in
  let altered = { market with rows = earlier @ [ altered_last ] } in
  let history (m : Market.t) : Engine.dated_state list =
    (Engine.run (module Momentum_strategy) ~initial_cash:10000 m).history
  in
  let original_history = history market in
  let altered_history = history altered in
  let n = List.length earlier in
  let first_n (l : Engine.dated_state list) : Engine.dated_state list =
    List.filteri (fun i _ -> i < n) l
  in
  assert_history_equal (first_n original_history) (first_n altered_history);
  (* The change is visible on the final date only: momentum now sells 5 APEX
     at 2000 (cash 11000) and buys 11000 / 9900 = 1 BOLT. *)
  assert_equal ~printer:string_of_dated_state
    {
      date = "2024-02-07";
      cash = 1100;
      holdings = [ ("BOLT", 1) ];
      value = 11000;
    }
    (List.nth altered_history n)

(* Market parsing *)
let test_load_handout_structure _ =
  let market = load_market_exn "handout.csv" in
  assert_equal ~printer:(String.concat ", ") [ "ALFA"; "BETA" ]
    market.securities;
  assert_equal ~printer:string_of_rows
    [
      { date = "2024-01-02"; prices = [ ("ALFA", 1000); ("BETA", 2500) ] };
      { date = "2024-01-03"; prices = [ ("ALFA", 1200); ("BETA", 2000) ] };
      { date = "2024-01-04"; prices = [ ("ALFA", 1100); ("BETA", 2100) ] };
    ]
    market.rows

let test_load_missing_file _ =
  match Market.load (data_path "no-such-market.csv") with
  | Ok _ -> assert_failure "Expected an error for a missing market file"
  | Error _ -> ()

let string_of_cents_result (r : (int, string) result) : string =
  match r with Ok c -> Printf.sprintf "Ok %d" c | Error msg -> "Error " ^ msg

let parse_cents_accepts (s : string) (expected : int) : test =
  "parse_cents accepts " ^ s >:: fun _ ->
  assert_equal ~printer:string_of_cents_result (Ok expected)
    (Market.parse_cents s)

let parse_cents_rejects (s : string) : test =
  Printf.sprintf "parse_cents rejects %S" s >:: fun _ ->
  match Market.parse_cents s with
  | Ok c -> assert_failure (Printf.sprintf "Accepted %S as %d cents" s c)
  | Error _ -> ()

let format_cents_test (cents : int) (expected : string) : test =
  Printf.sprintf "format_cents %d" cents >:: fun _ ->
  assert_equal ~printer:Fun.id expected (Market.format_cents cents)

let market_parsing_tests =
  [
    "load handout.csv into integer cents" >:: test_load_handout_structure;
    "load reports a missing file" >:: test_load_missing_file;
    parse_cents_accepts "10.00" 1000;
    parse_cents_accepts "0.01" 1;
    parse_cents_accepts "10000.01" 1000001;
    parse_cents_accepts "007.50" 750;
    parse_cents_rejects "";
    parse_cents_rejects "10";
    parse_cents_rejects "10.0";
    parse_cents_rejects "10.000";
    parse_cents_rejects ".50";
    parse_cents_rejects "-1.00";
    parse_cents_rejects "+1.00";
    parse_cents_rejects "0.00";
    parse_cents_rejects "1,000.00";
    parse_cents_rejects "$1.00";
    parse_cents_rejects " 1.00";
    parse_cents_rejects "1.00 ";
    parse_cents_rejects "1e3.00";
    parse_cents_rejects "46116860184273880.00";
    format_cents_test 0 "0.00";
    format_cents_test 5 "0.05";
    format_cents_test 100 "1.00";
    format_cents_test 1033345 "10333.45";
  ]

(* Portfolio accounting: individual rules *)
let row_ab : Market.row =
  { date = "2024-01-02"; prices = [ ("ALFA", 1000); ("BETA", 2500) ] }

let assert_portfolio ~(cash : int) ~(holdings : (string * int) list)
    (p : Portfolio.t) : unit =
  assert_equal ~msg:"cash" ~printer:string_of_int cash (Portfolio.cash p);
  assert_equal ~msg:"holdings" ~printer:string_of_holdings holdings
    (Portfolio.holdings p)

(* [rejected_order_test name ord] checks that applying [ord] to a portfolio of
   10000 cash and 2 ALFA leaves it unchanged. *)
let rejected_order_test (name : string) (ord : Portfolio.order) : test =
  "rejects " ^ name >:: fun _ ->
  let p =
    Portfolio.apply_order row_ab (Portfolio.init 12000)
      { security = "ALFA"; direction = Buy; quantity = 2 }
  in
  assert_portfolio ~cash:10000 ~holdings:[ ("ALFA", 2) ] p;
  assert_portfolio ~cash:10000
    ~holdings:[ ("ALFA", 2) ]
    (Portfolio.apply_order row_ab p ord)

let test_buy_with_exactly_all_cash _ =
  Portfolio.apply_order row_ab (Portfolio.init 10000)
    { security = "ALFA"; direction = Buy; quantity = 10 }
  |> assert_portfolio ~cash:0 ~holdings:[ ("ALFA", 10) ]

let test_buy_one_cent_short _ =
  Portfolio.apply_order row_ab (Portfolio.init 9999)
    { security = "ALFA"; direction = Buy; quantity = 10 }
  |> assert_portfolio ~cash:9999 ~holdings:[]

let test_sell_all_removes_holding _ =
  Portfolio.apply_orders row_ab (Portfolio.init 10000)
    [
      { security = "ALFA"; direction = Buy; quantity = 3 };
      { security = "ALFA"; direction = Sell; quantity = 3 };
    ]
  |> assert_portfolio ~cash:10000 ~holdings:[]

(* Start with 1500 cash and 1 ALFA (1000). Buying 1 BETA (2500) needs the
   proceeds of selling ALFA, so it succeeds only if the sale comes first. *)
let test_order_sequence_matters _ =
  let p =
    Portfolio.apply_order row_ab (Portfolio.init 2500)
      { security = "ALFA"; direction = Buy; quantity = 1 }
  in
  let sell_alfa : Portfolio.order =
    { security = "ALFA"; direction = Sell; quantity = 1 }
  in
  let buy_beta : Portfolio.order =
    { security = "BETA"; direction = Buy; quantity = 1 }
  in
  Portfolio.apply_orders row_ab p [ sell_alfa; buy_beta ]
  |> assert_portfolio ~cash:0 ~holdings:[ ("BETA", 1) ];
  Portfolio.apply_orders row_ab p [ buy_beta; sell_alfa ]
  |> assert_portfolio ~cash:2500 ~holdings:[]

let total_return_test (initial_cash : int) (final_value : int)
    (expected : float) : test =
  Printf.sprintf "total_return %d -> %d" initial_cash final_value >:: fun _ ->
  assert_equal ~cmp:(cmp_float ~epsilon:1e-9) ~printer:string_of_float expected
    (Portfolio.total_return ~initial_cash ~final_value)

let portfolio_tests =
  [
    "rejected orders followed by valid orders"
    >:: test_portfolio_order_rejection_and_sequence;
    rejected_order_test "zero quantity"
      { security = "ALFA"; direction = Buy; quantity = 0 };
    rejected_order_test "negative quantity sell"
      { security = "ALFA"; direction = Sell; quantity = -1 };
    rejected_order_test "unknown security"
      { security = "ZETA"; direction = Buy; quantity = 1 };
    rejected_order_test "buy costing more than cash"
      { security = "BETA"; direction = Buy; quantity = 5 };
    rejected_order_test "sell of more shares than held"
      { security = "ALFA"; direction = Sell; quantity = 3 };
    rejected_order_test "sell of a security not held"
      { security = "BETA"; direction = Sell; quantity = 1 };
    "accepts a buy costing exactly all cash" >:: test_buy_with_exactly_all_cash;
    "rejects a buy one cent short" >:: test_buy_one_cent_short;
    "selling every share removes the holding" >:: test_sell_all_removes_holding;
    "sale proceeds fund a later buy, not an earlier one"
    >:: test_order_sequence_matters;
    total_return_test 10000 10600 6.0;
    total_return_test 10000 9200 (-8.0);
    total_return_test 1000000 1033345 3.3345;
  ]

(* Report formatting *)

(* The Accounting Reference scenario on handout.csv, as given in the handout. *)
let accounting_reference_result : Engine.result =
  {
    strategy_name = "my-strategy";
    start_date = "2024-01-02";
    end_date = "2024-01-04";
    initial_cash = 10000;
    final_cash = 6300;
    final_holdings = [ ("ALFA", 2); ("BETA", 1) ];
    final_value = 10600;
    total_return = 6.0;
    history = [];
  }

let test_summary_accounting_reference _ =
  assert_equal ~printer:Fun.id
    (String.concat "\n"
       [
         "Strategy: my-strategy";
         "Period: 2024-01-02 to 2024-01-04";
         "Initial cash: $100.00";
         "Final cash: $63.00";
         "Final holdings:";
         "  ALFA: 2 shares";
         "  BETA: 1 share";
         "Final portfolio value: $106.00";
         "Total return: 6.00%";
       ])
    (Report.format_summary accounting_reference_result)

(* A loss of one cent on $10,000.00 is -0.0001%, which must not print as
   "-0.00%"; empty holdings print as "none". *)
let test_summary_tiny_loss_no_holdings _ =
  let res =
    {
      accounting_reference_result with
      initial_cash = 1000000;
      final_cash = 999999;
      final_holdings = [];
      final_value = 999999;
      total_return =
        Portfolio.total_return ~initial_cash:1000000 ~final_value:999999;
    }
  in
  let lines = String.split_on_char '\n' (Report.format_summary res) in
  assert_equal ~printer:Fun.id "Final holdings: none" (List.nth lines 4);
  assert_equal ~printer:Fun.id "Total return: 0.00%" (List.nth lines 6)

let read_lines (filename : string) : string list =
  In_channel.with_open_bin filename In_channel.input_all
  |> String.split_on_char '\n'
  |> List.filter (fun line -> line <> "")

let test_write_equity_csv _ =
  let market = load_market_exn "handout.csv" in
  let res =
    Engine.run
      (module Buy_and_hold_strategy)
      ~hold_symbol:"ALFA" ~initial_cash:10000 market
  in
  let file = Filename.temp_file "a2-equity" ".csv" in
  (match Report.write_equity_csv file res with
  | Ok () -> ()
  | Error msg -> assert_failure msg);
  let lines = read_lines file in
  Sys.remove file;
  assert_equal ~printer:(String.concat " | ")
    [
      "date,value";
      "2024-01-02,100.00";
      "2024-01-03,120.00";
      "2024-01-04,110.00";
    ]
    lines

let test_write_equity_csv_error _ =
  let market = load_market_exn "handout.csv" in
  let res = Engine.run (module Cash_strategy) ~initial_cash:10000 market in
  match Report.write_equity_csv "no-such-directory/equity.csv" res with
  | Ok () -> assert_failure "Expected an error for an unwritable path"
  | Error _ -> ()

let report_tests =
  [
    "summary for the Accounting Reference scenario"
    >:: test_summary_accounting_reference;
    "summary with no holdings and a tiny loss"
    >:: test_summary_tiny_loss_no_holdings;
    "equity CSV for buy-and-hold ALFA on handout.csv" >:: test_write_equity_csv;
    "equity CSV reports an unwritable path" >:: test_write_equity_csv_error;
  ]

let suite =
  "A2 Validation Suite"
  >::: [
         "Group 1: Cash Strategy"
         >::: [ "cash on handout.csv" >:: test_cash_handout ];
         "Group 2: Buy-and-Hold Strategy"
         >::: [
                "buy-and-hold ALFA on handout.csv"
                >:: test_buy_and_hold_handout_alfa;
                "buy-and-hold APEX on custom.csv"
                >:: test_buy_and_hold_custom_apex;
                "buy-and-hold OPAL (unaffordable) on edge-cases.csv"
                >:: test_buy_and_hold_edge_unaffordable;
              ];
         "Group 3: Stateful (Momentum) Strategy"
         >::: [
                "momentum on handout.csv" >:: test_momentum_handout;
                "momentum on custom.csv" >:: test_momentum_custom;
                "momentum on edge-cases.csv" >:: test_momentum_edge_cases;
              ];
         "Engine: current row only"
         >::: [
                "step receives each row once, in order"
                >:: test_engine_passes_each_row_once_in_order;
                "changing a later row leaves earlier states unchanged"
                >:: test_later_row_does_not_change_earlier_states;
              ];
         "Market Parsing" >::: market_parsing_tests;
         "Portfolio Accounting Rules" >::: portfolio_tests;
         "Report Formatting" >::: report_tests;
       ]

let () = run_test_tt_main suite
