extends Node2D

var vegetable_list: Array[Vegetable] = []
var positions: Array[Vector2] = []
@export var max_size = 10

func _ready() -> void:
	positions.append($Example1.position)
	positions.append($Example2.position)
	for i in range(2, max_size):
		positions.append(positions.back() + Vector2.RIGHT * 65)

func clear():
	while not vegetable_list.is_empty():
		pop_queue()

func push(vegetable: Vegetable):
	if vegetable_list.size() == max_size:
		return
	vegetable.reparent(self)
	vegetable.position = positions[vegetable_list.size()]
	vegetable.speed = 0
	vegetable.show()
	vegetable_list.append(vegetable)
	vegetable_list[0].scale = $Example1.scale

func pop_queue():
	if vegetable_list.is_empty():
		return
	var vegetable = vegetable_list[0]
	vegetable_list.erase(vegetable)
	for i in range(vegetable_list.size()):
		vegetable_list[i].position = positions[i]
	if not vegetable_list.is_empty():
		vegetable_list[0].scale = $Example1.scale
	vegetable.queue_free()

func use() -> String:
	if vegetable_list.is_empty():
		return ""
	vegetable_list[0].use(get_parent())	
	var res = vegetable_list[0].id

	pop_queue()
	return res
