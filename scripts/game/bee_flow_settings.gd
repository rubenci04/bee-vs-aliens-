extends RefCounted
const FADE_SECONDS := 0.22
const INTRO_READ_HOLD := 2.0
const TAGLINE_TOP := 0.30
const MENU_TOP := 0.40
const TITLE_LOGO_HEIGHT := 180.0
const RANKS := [
 {"rank":"S","released":.85,"score":100000},
 {"rank":"A","released":.65,"score":60000},
 {"rank":"B","released":.40,"score":25000},
 {"rank":"C","released":.0,"score":0}
]
static func rank_for(released: int, total: int, score: int) -> String:
 var fraction := float(released)/maxi(total,1)
 for row in RANKS:
  if fraction>=row.released and score>=row.score: return row.rank
 return "C"
