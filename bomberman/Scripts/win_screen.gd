extends CanvasLayer

func _ready():
	# Load the texture
	var victory_texture = load("res://Sprites/victory.png")  # Adjust the path to match your image location
	$TextureRect.texture = victory_texture
	
	# Make sure it covers the entire viewport
	$TextureRect.size = get_viewport().size

func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
