(** One-day momentum strategy: selects the security with the largest strictly
    positive one-day price increase (breaking ties in market-file order) and
    rotates the entire portfolio into that target when the target changes. *)

include Strategy.S
