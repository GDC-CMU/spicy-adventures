extends Node2D

func change_content(texture: Texture2D, description: String):
	$Description.text = description
	$Sprite.texture = texture
