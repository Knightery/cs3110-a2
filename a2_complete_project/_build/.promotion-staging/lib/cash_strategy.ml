(* AF: [()] represents the stateless cash strategy.
   RI: none. *)
type state = unit

let name = "cash"
let init (_ : string option) : state = ()

let step (st : state) (_ : Market.row) (_ : Portfolio.t) :
    state * Portfolio.order list =
  (st, [])
