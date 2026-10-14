type row = { date : string; prices : (string * int) list }
type t = { securities : string list; rows : row list }

let is_digits (s : string) : bool =
  let len = String.length s in
  len > 0
  &&
  let rec loop i =
    if i >= len then true
    else match s.[i] with '0' .. '9' -> loop (i + 1) | _ -> false
  in
  loop 0

let parse_cents (s : string) : (int, string) result =
  match String.split_on_char '.' s with
  | [ dollars_str; cents_str ]
    when is_digits dollars_str
         && String.length cents_str = 2
         && is_digits cents_str -> (
      match (int_of_string_opt dollars_str, int_of_string_opt cents_str) with
      | Some d, Some c when d <= (max_int - c) / 100 ->
          (* The guard ensures [(d * 100) + c] cannot overflow. *)
          let total = (d * 100) + c in
          if total > 0 then Ok total
          else Error (Printf.sprintf "Amount must be positive: %s" s)
      | _ -> Error (Printf.sprintf "Amount is too large: %s" s))
  | _ ->
      Error
        (Printf.sprintf
           "Invalid dollar amount %S (expected positive DOLLARS.CC)" s)

let format_cents (cents : int) : string =
  let abs_c = abs cents in
  let d = abs_c / 100 in
  let c = abs_c mod 100 in
  if cents < 0 then Printf.sprintf "-%d.%02d" d c
  else Printf.sprintf "%d.%02d" d c

let price_of (row : row) (security : string) : int option =
  List.assoc_opt security row.prices

let parse_prices (securities : string list) (fields : string list) :
    ((string * int) list, string) result =
  let rec loop secs flds acc =
    match (secs, flds) with
    | [], [] -> Ok (List.rev acc)
    | sec :: rest_secs, fld :: rest_flds -> (
        match parse_cents fld with
        | Ok p -> loop rest_secs rest_flds ((sec, p) :: acc)
        | Error msg -> Error msg)
    | _ -> Error "Row field count does not match header column count"
  in
  loop securities fields []

let parse_rows (securities : string list) (raw_rows : string list list) :
    (row list, string) result =
  let rec loop rows acc =
    match rows with
    | [] -> Ok (List.rev acc)
    | [] :: _ -> Error "Empty row in market file"
    | (date :: price_fields) :: rest -> (
        match parse_prices securities price_fields with
        | Ok prices -> loop rest ({ date; prices } :: acc)
        | Error msg -> Error msg)
  in
  loop raw_rows []

let load (filename : string) : (t, string) result =
  try
    let csv_data = Csv.load filename in
    match csv_data with
    | ("date" :: securities) :: data_rows
      when securities <> [] && data_rows <> [] -> (
        match parse_rows securities data_rows with
        | Ok rows -> Ok { securities; rows }
        | Error msg -> Error msg)
    | _ ->
        Error
          (Printf.sprintf
             "Market file %S must have a 'date,...' header and at least one \
              data row"
             filename)
  with
  | Sys_error msg -> Error (Printf.sprintf "Cannot open market file: %s" msg)
  | Csv.Failure (r, c, msg) ->
      Error (Printf.sprintf "CSV parse error at (%d, %d): %s" r c msg)
