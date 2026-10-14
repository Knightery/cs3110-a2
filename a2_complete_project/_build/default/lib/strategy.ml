module type S = sig
  type state

  val name : string
  val init : string option -> state
  val step : state -> Market.row -> Portfolio.t -> state * Portfolio.order list
end
