class_name EndingRouter
extends Node
## Al terminar el último nivel, abre el final que corresponde a lo que hizo Lucía en la noche.

const ENDINGS: Dictionary[GameState.Ending, String] = {
	GameState.Ending.RETURNED: "res://src/cinematics/endings/ending_returned.tscn",
	GameState.Ending.DEAL: "res://src/cinematics/endings/ending_deal.tscn",
	GameState.Ending.TAKEN: "res://src/cinematics/endings/ending_taken.tscn",
}


## Elige el final y lo abre.
func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred(ENDINGS[GameState.choose_ending()])
