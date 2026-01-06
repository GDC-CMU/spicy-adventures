extends Node2D

@export_multiline var description: String
	

func _on_button_pressed() -> void:
	get_parent().change_content($Enemy.texture, description) # Replace with function body.
