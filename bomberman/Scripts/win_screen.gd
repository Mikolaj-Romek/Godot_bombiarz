extends CanvasLayer

func _ready():
	# Load the texture
	var victory_texture = load("res://Sprites/victory.png")
	$TextureRect.texture = victory_texture
	
	# Set up the TextureRect
	$TextureRect.custom_minimum_size = get_viewport().size
	$TextureRect.size = get_viewport().size
	$TextureRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	$TextureRect.anchor_right = 1
	$TextureRect.anchor_bottom = 1
	$TextureRect.offset_right = 0
	$TextureRect.offset_bottom = 0

func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
