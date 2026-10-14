(* AF: [{ prev_prices; target }] represents the momentum strategy's state,
   where [prev_prices] is [None] before the first trading date and
   [Some prices] containing the previous trading date's [(security, price)]
   list thereafter, and [target] is the currently selected target security
   ([None] when the target is "none", or [Some sym] when [sym] is selected).
   RI: If [prev_prices] is [Some prices], every price in [prices] is > 0. *)
type state = {
  prev_prices : (string * int) list option;
  target : string option;
}

let name = "momentum"
let init (_ : string option) : state = { prev_prices = None; target = None }

let select_target (prev_prices : (string * int) list)
    (curr_prices : (string * int) list) : (string * int) option =
  let best =
    List.fold_left
      (fun acc (sec, curr_p) ->
        match List.assoc_opt sec prev_prices with
        | None -> acc
        | Some prev_p -> (
            let increase = curr_p - prev_p in
            if increase <= 0 then acc
            else
              match acc with
              | None -> Some (sec, curr_p, increase)
              | Some (_, _, best_inc) ->
                  if increase > best_inc then Some (sec, curr_p, increase)
                  else acc))
      None curr_prices
  in
  match best with None -> None | Some (sec, curr_p, _) -> Some (sec, curr_p)

let step (st : state) (row : Market.row) (portfolio : Portfolio.t) :
    state * Portfolio.order list =
  match st.prev_prices with
  | None -> ({ prev_prices = Some row.prices; target = None }, [])
  | Some prev -> (
      match select_target prev row.prices with
      | None -> ({ prev_prices = Some row.prices; target = st.target }, [])
      | Some (selected_sec, selected_price) ->
          if st.target = Some selected_sec then
            ({ prev_prices = Some row.prices; target = st.target }, [])
          else
            let held = Portfolio.holdings portfolio in
            let sell_orders =
              List.map
                (fun (sec, qty) ->
                  { Portfolio.security = sec; direction = Sell; quantity = qty })
                held
            in
            (* Selling every holding at today's prices converts the whole
               portfolio to cash, so the cash available for the buy order is
               the portfolio's value at today's prices. *)
            let available_cash = Portfolio.value row portfolio in
            let buy_qty = available_cash / selected_price in
            let orders =
              if buy_qty > 0 then
                sell_orders
                @ [
                    {
                      Portfolio.security = selected_sec;
                      direction = Buy;
                      quantity = buy_qty;
                    };
                  ]
              else sell_orders
            in
            ( { prev_prices = Some row.prices; target = Some selected_sec },
              orders ))
