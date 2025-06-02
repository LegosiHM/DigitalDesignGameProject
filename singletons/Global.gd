extends Node

# ------------------------------------------------------------------------------
# PLAYER STATUS VARIABLES
# ------------------------------------------------------------------------------

# Whether the player has collcted jewelry
# This boolean can be toggled from other objects (e.g. collectibles)
var has_hj_power: bool = false
var is_changing_scene := false
var current_level: String = ""
