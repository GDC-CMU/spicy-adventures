extends Level

func _ready() -> void:
	super._ready()
	$IndianMasalaChilli.speed = 0
	

func _on_win_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# The zone signal arrives during physics; detach collision bodies later.
		get_parent().to_title_screen.call_deferred()
