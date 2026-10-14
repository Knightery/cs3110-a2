(* AF: [{ target; acted }] represents a buy-and-hold strategy targeting
   security [target], where [acted] is [false] before the first trading date
   and [true] after the first trading date has been processed.
   RI: none. *)
type state = { target : string; acted : bool }

let name = "buy-and-hold"

let init (hold_symbol : string option) : state =
  match hold_symbol with
  | Some sym -> { target = sym; acted = false }
  | None -> { target = ""; acted = true }

let step (st : state) (row : Market.row) (portfolio : Portfolio.t) :
    state * Portfolio.order list =
  if st.acted then (st, [])
  else
    let next_st = { st with acted = true } in
    match Market.price_of row st.target with
    | None -> (next_st, [])
    | Some price ->
        let qty = Portfolio.cash portfolio / price in
        let orders =
          if qty > 0 then
            [
              {
                Portfolio.security = st.target;
                direction = Buy;
                quantity = qty;
              };
            ]
          else []
        in
        (next_st, orders)
