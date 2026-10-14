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
              ];
         "Group 3: Stateful (Momentum) Strategy"
         >::: [
                "momentum on handout.csv" >:: test_momentum_handout;
                "momentum on custom.csv" >:: test_momentum_custom;
              ];
         "Portfolio Accounting Rules"
         >::: [
                "rejected orders followed by valid orders"
                >:: test_portfolio_order_rejection_and_sequence;
              ];
       ]

let () = run_test_tt_main suite
