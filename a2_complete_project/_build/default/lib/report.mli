(** Equity CSV generation and human-readable summary formatting. *)

(** [write_equity_csv filename res] writes the dated portfolio values from
    [res.history] to [filename] with header ["date,value"] and values formatted
    as ["DOLLARS.CC"]. *)
val write_equity_csv : string -> Engine.result -> (unit, string) result

(** [format_summary res] produces the human-readable final summary string for
    [res], omitting securities with zero shares held. *)
val format_summary : Engine.result -> string
