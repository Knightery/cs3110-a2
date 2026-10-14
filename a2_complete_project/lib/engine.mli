(** Strategy-independent backtesting simulation engine. *)

(** [dated_state] records the portfolio's cash (in cents), non-zero share
    holdings, and total portfolio value (in cents) after processing all orders
    on [date]. *)
type dated_state = {
  date : string;
  cash : int;
  holdings : (string * int) list;
  value : int;
}

(** [result] summarizes a completed simulation across all dates in a market
    dataset. *)
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

(** [run (module Strat) ?hold_symbol ~initial_cash market] executes [Strat]
    across every date in [market.rows] in chronological order, starting with
    [initial_cash] cents and no shares. On each date, [Strat.step] receives only
    that date's price row and current portfolio. *)
val run :
  (module Strategy.S) ->
  ?hold_symbol:string ->
  initial_cash:int ->
  Market.t ->
  result
