type dated_state = {
  date : string;
  cash : int;
  holdings : (string * int) list;
  value : int;
}

type result = {
  strategy_name : string;
  start_date : string;
  end_date : string;
  initial_cash : int;
  final_cash : int;
  final_holdings : (string * int) list;
  final_value : int;
  total_return : float;
  history : dated_state list;
}

let run (module Strat : Strategy.S) ?(hold_symbol : string option)
    ~(initial_cash : int) (market : Market.t) : result =
  let init_state = Strat.init hold_symbol in
  let init_portfolio = Portfolio.init initial_cash in
  let _, final_portfolio, rev_history =
    List.fold_left
      (fun (strat_st, port, acc) (row : Market.row) ->
        let next_strat_st, orders = Strat.step strat_st row port in
        let next_port = Portfolio.apply_orders row port orders in
        let day_val = Portfolio.value row next_port in
        let snap =
          {
            date = row.date;
            cash = Portfolio.cash next_port;
            holdings = Portfolio.holdings next_port;
            value = day_val;
          }
        in
        (next_strat_st, next_port, snap :: acc))
      (init_state, init_portfolio, [])
      market.rows
  in
  let history = List.rev rev_history in
  let start_date, end_date =
    match history with
    | [] -> ("", "")
    | first :: _ ->
        let last = List.hd rev_history in
        (first.date, last.date)
  in
  let final_cash = Portfolio.cash final_portfolio in
  let final_holdings = Portfolio.holdings final_portfolio in
  let final_value =
    match rev_history with last :: _ -> last.value | [] -> initial_cash
  in
  let total_return = Portfolio.total_return ~initial_cash ~final_value in
  {
    strategy_name = Strat.name;
    start_date;
    end_date;
    initial_cash;
    final_cash;
    final_holdings;
    final_value;
    total_return;
    history;
  }
