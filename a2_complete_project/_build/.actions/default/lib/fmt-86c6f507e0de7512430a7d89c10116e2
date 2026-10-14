(** Representation and parsing of daily market price data. *)

(** [row] represents a single trading date's observation, associating each
    security name (in market-file column order) with its closing price in
    integer cents. *)
type row = { date : string; prices : (string * int) list }

(** [t] represents a parsed market dataset containing the list of security names
    in column order and the chronological list of dated price rows. *)
type t = { securities : string list; rows : row list }

(** [parse_cents s] parses a positive dollar string formatted with one or more
    digits before the decimal point and exactly two digits after (e.g.,
    ["10.00"]) into integer cents (e.g., [Ok 1000]). Returns [Error msg] if [s]
    does not match this format or is not strictly positive. *)
val parse_cents : string -> (int, string) result

(** [format_cents c] formats a nonnegative integer cent amount [c] as a dollar
    string with two decimal places and no dollar sign or commas (e.g.,
    [format_cents 10000 = "100.00"]). *)
val format_cents : int -> string

(** [price_of row security] returns [Some price] in integer cents if [security]
    is present in [row], or [None] if [security] is unknown. *)
val price_of : row -> string -> int option

(** [load filename] reads and parses the market CSV file at [filename] using
    [Csv.load]. Returns [Error msg] if the file cannot be opened or is
    malformed. *)
val load : string -> (t, string) result
