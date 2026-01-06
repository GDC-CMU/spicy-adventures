extends Node2D


func _on_peppers_button_pressed() -> void:
	$PepperCompendium.show()
	$Base.hide()

func back_to_compendium() -> void:
	$PepperCompendium.hide()
	$EnemyCompendium.hide()
	$Base.show()


func _on_button_pressed() -> void:
	$EnemyCompendium.show()
	$Base.hide() # Replace with function body.
