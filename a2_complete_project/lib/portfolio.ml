type direction = Buy | Sell
type order = { security : string; direction : direction; quantity : int }

(* AF: [{ cash; holdings }] represents a portfolio with [cash] cents and
   whole-share positions given by the association list [holdings]. Any security
   not present in [holdings] has 0 shares.
   RI: [cash >= 0]; every [(sec, qty)] in [holdings] satisfies [qty > 0]; keys
   in [holdings] are unique and sorted in ascending lexicographical order. *)
type t = { cash : int; holdings : (string * int) list }

let init (initial_cash : int) : t = { cash = initial_cash; holdings = [] }
let cash (p : t) : int = p.cash

let shares_of (p : t) (security : string) : int =
  match List.assoc_opt security p.holdings with Some qty -> qty | None -> 0

let holdings (p : t) : (string * int) list = p.holdings

let set_holding (holdings : (string * int) list) (security : string)
    (new_qty : int) : (string * int) list =
  let without = List.remove_assoc security holdings in
  if new_qty <= 0 then without
  else
    List.sort
      (fun (s1, _) (s2, _) -> String.compare s1 s2)
      ((security, new_qty) :: without)

let apply_order (row : Market.row) (p : t) (ord : order) : t =
  if ord.quantity <= 0 then p
  else
    match Market.price_of row ord.security with
    | None -> p
    | Some price -> (
        let trade_amount = ord.quantity * price in
        match ord.direction with
        | Buy ->
            if p.cash < trade_amount then p
            else
              let current_qty = shares_of p ord.security in
              {
                cash = p.cash - trade_amount;
                holdings =
                  set_holding p.holdings ord.security
                    (current_qty + ord.quantity);
              }
        | Sell ->
            let current_qty = shares_of p ord.security in
            if current_qty < ord.quantity then p
            else
              {
                cash = p.cash + trade_amount;
                holdings =
                  set_holding p.holdings ord.security
                    (current_qty - ord.quantity);
              })

let apply_orders (row : Market.row) (p : t) (ords : order list) : t =
  List.fold_left (apply_order row) p ords

let value (row : Market.row) (p : t) : int =
  let holdings_value =
    List.fold_left
      (fun acc (sec, qty) ->
        match Market.price_of row sec with
        | Some price -> acc + (qty * price)
        | None -> acc)
      0 p.holdings
  in
  p.cash + holdings_value

let total_return ~(initial_cash : int) ~(final_value : int) : float =
  let diff = float_of_int (final_value - initial_cash) in
  let init_f = float_of_int initial_cash in
  diff /. init_f *. 100.0
