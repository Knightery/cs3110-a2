(** Portfolio state, order execution, and valuation in integer cents. *)

(** [direction] indicates whether an order buys or sells shares. *)
type direction = Buy | Sell

(** [order] represents a proposed trade of [quantity] whole shares of [security]
    in [direction]. *)
type order = { security : string; direction : direction; quantity : int }

(** Abstract representation of a portfolio's cash and whole-share holdings. *)
type t

(** [init initial_cash] creates a portfolio starting with [initial_cash] cents
    and no share holdings. Requires: [initial_cash >= 0]. *)
val init : int -> t

(** [cash p] is the current cash balance of portfolio [p] in integer cents. *)
val cash : t -> int

(** [shares_of p security] is the number of whole shares of [security] held in
    [p] (returns [0] if none are held). *)
val shares_of : t -> string -> int

(** [holdings p] returns the list of [(security, shares)] pairs for all
    securities with strictly positive share counts, sorted by security name. *)
val holdings : t -> (string * int) list

(** [apply_order row p ord] processes [ord] against [p] using the closing prices
    in [row]. Returns [p] unchanged if [ord] is rejected (quantity <= 0, unknown
    security, insufficient cash for [Buy], or insufficient shares for [Sell]).
*)
val apply_order : Market.row -> t -> order -> t

(** [apply_orders row p ords] processes [ords] sequentially from left to right
    using [apply_order row]. A rejected order leaves [p] unchanged and does not
    prevent later orders from being processed. *)
val apply_orders : Market.row -> t -> order list -> t

(** [value row p] calculates the total portfolio value in integer cents:
    [cash p] plus each holding valued at its closing price in [row]. *)
val value : Market.row -> t -> int

(** [total_return ~initial_cash ~final_value] computes the percentage total
    return [((final_value - initial_cash) / initial_cash) * 100.0] using
    floating-point arithmetic. *)
val total_return : initial_cash:int -> final_value:int -> float
