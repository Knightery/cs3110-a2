let write_equity_csv (filename : string) (res : Engine.result) :
    (unit, string) result =
  let rows =
    [ "date"; "value" ]
    :: List.map
         (fun (snap : Engine.dated_state) ->
           [ snap.date; Market.format_cents snap.value ])
         res.history
  in
  try
    Csv.save filename rows;
    Ok ()
  with Sys_error msg ->
    Error (Printf.sprintf "Cannot write equity CSV: %s" msg)

let format_holding ((sec, qty) : string * int) : string =
  let unit_str = if qty = 1 then "share" else "shares" in
  Printf.sprintf "  %s: %d %s" sec qty unit_str

let format_percent (pct : float) : string =
  let s = Printf.sprintf "%.2f" pct in
  (* A tiny loss such as -0.001% would otherwise print as "-0.00". *)
  if s = "-0.00" then "0.00" else s

let format_summary (res : Engine.result) : string =
  let holdings_header =
    if res.final_holdings = [] then "Final holdings: none"
    else "Final holdings:"
  in
  let header_lines =
    [
      Printf.sprintf "Strategy: %s" res.strategy_name;
      Printf.sprintf "Period: %s to %s" res.start_date res.end_date;
      Printf.sprintf "Initial cash: $%s" (Market.format_cents res.initial_cash);
      Printf.sprintf "Final cash: $%s" (Market.format_cents res.final_cash);
      holdings_header;
    ]
  in
  let holding_lines = List.map format_holding res.final_holdings in
  let footer_lines =
    [
      Printf.sprintf "Final portfolio value: $%s"
        (Market.format_cents res.final_value);
      Printf.sprintf "Total return: %s%%" (format_percent res.total_return);
    ]
  in
  String.concat "\n" (header_lines @ holding_lines @ footer_lines)
