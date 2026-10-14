(** Equity CSV generation and human-readable summary formatting. *)

(** [write_equity_csv filename res] writes the dated portfolio values from
    [res.history] to [filename] with header ["date,value"] and values formatted
    as ["DOLLARS.CC"]. Returns [Error msg] if [filename] cannot be written. *)
val write_equity_csv : string -> Engine.result -> (unit, string) result

(** [format_summary res] produces the human-readable final summary string for
    [res]: strategy name, period, initial and final cash, final holdings (or
    ["none"]), final portfolio value, and total return rounded to two decimal
    places. Securities with zero shares held are omitted. *)
val format_summary : Engine.result -> string
