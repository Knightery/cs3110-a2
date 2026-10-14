(** Common interface for all trading strategies. *)

module type S = sig
  (** Abstract representation of a strategy's private state carried from one
      trading date to the next. *)
  type state

  (** [name] is the canonical strategy name (e.g., ["cash"], ["buy-and-hold"],
      or ["momentum"]). *)
  val name : string

  (** [init hold_symbol] creates the strategy's initial private state prior to
      processing the first trading date. *)
  val init : string option -> state

  (** [step st row portfolio] advances the strategy on a single date given only
      that date's price observation [row] and the current [portfolio], returning
      the updated private state and proposed orders for that date. *)
  val step : state -> Market.row -> Portfolio.t -> state * Portfolio.order list
end
