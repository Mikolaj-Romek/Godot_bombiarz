extends CharacterBody2D

const SPEED = 50.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var bomb_scene = preload("res://Scenes/bomb.tscn")
var max_bombs = 1
var current_bombs = 0
var is_alive = true

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
		
	# Horizontal movement
	var direction_x := Input.get_axis("ui_left", "ui_right")
	if direction_x != 0:
		velocity.x = direction_x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
			
	if direction_x > 0:
		animated_sprite.flip_h = true
	elif direction_x < 0:
		animated_sprite.flip_h = false
	
	# Vertical movement
	var direction_y := Input.get_axis("ui_up", "ui_down")
	if direction_y != 0:
		velocity.y = direction_y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	if direction_x != 0:
		animated_sprite.play("walk_side")
	elif direction_y < 0:
		animated_sprite.play("walk_up")
	elif direction_y > 0:
		animated_sprite.play("walk_down")
	else:
		animated_sprite.pause()

	# Apply the velocity
	move_and_slide()

func _input(event):
	if not is_alive:
		return
		
	if event.is_action_pressed("place_bomb") and current_bombs < max_bombs:
		var tilemap = get_parent().get_node("TileMap")
		var tile_pos = tilemap.local_to_map(global_position)
		var world_pos = tilemap.map_to_local(tile_pos)
		
		var bomb = bomb_scene.instantiate()
		bomb.global_position = world_pos
		bomb.tree_exiting.connect(func(): current_bombs -= 1)
		get_parent().add_child(bomb)
		current_bombs += 1

func die():
	if not is_alive:  # Prevent multiple death calls
		return
		
	is_alive = false
	velocity = Vector2.ZERO  # Stop movement
	
	# Play death animation if it exists
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished

	
	# Remove the player
	queue_free()
