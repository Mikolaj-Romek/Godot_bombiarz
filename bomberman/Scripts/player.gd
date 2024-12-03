# player.gd
extends CharacterBody2D

const SPEED = 50.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var bomb_scene = preload("res://Scenes/bomb.tscn")
var max_bombs = 1
var current_bombs = 0
var is_alive = true
var bomb_range = 1
var can_place_random_bombs = false
var active_bomb_positions = []
var has_won = false

signal pickup_power(player_pos: Vector2i)

func _ready():
	add_to_group("player")

func _physics_process(delta: float) -> void:
	if not is_alive or has_won:
		return
		
	# Check for power-ups after movement
	var tilemap = get_parent().get_node("TileMap")
	var current_tile_pos = tilemap.local_to_map(global_position)
	pickup_power.emit(current_tile_pos)
		
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
	if not is_alive or has_won:
		return
		
	if event.is_action_pressed("place_bomb") and current_bombs < max_bombs:
		place_normal_bomb()
	elif event.is_action_pressed("random_bomb") and current_bombs < max_bombs and can_place_random_bombs:
		place_random_bomb()

func place_normal_bomb():
	var tilemap = get_parent().get_node("TileMap")
	var tile_pos = tilemap.local_to_map(global_position)
	
	# Check if there's a brick at this position
	var tile_data = tilemap.get_cell_tile_data(2, tile_pos)
	if tile_data != null:
		return  # Don't place bomb if there's a brick
		
	# Check if there's already a bomb at this position
	if tile_pos in active_bomb_positions:
		return  # Don't place bomb if there's already one there
		
	var world_pos = tilemap.map_to_local(tile_pos)
	var bomb = bomb_scene.instantiate()
	bomb.global_position = world_pos
	bomb.explosion_range = bomb_range
	
	# Add cleanup for when bomb is removed
	bomb.tree_exiting.connect(func(): 
		current_bombs -= 1
		active_bomb_positions.erase(tile_pos)
	)
	
	get_parent().add_child(bomb)
	current_bombs += 1
	active_bomb_positions.append(tile_pos)

func place_random_bomb():
	var tilemap = get_parent().get_node("TileMap")
	var valid_positions = []
	
	# Check all positions on the map
	for i in range(12):
		for j in range(30):
			var pos = Vector2i(j, i)
			var tile_data_1 = tilemap.get_cell_tile_data(1, pos)
			var tile_data_2 = tilemap.get_cell_tile_data(2, pos)
			
			# Add position if both layers are empty and there's no bomb
			if tile_data_1 == null and tile_data_2 == null and not (pos in active_bomb_positions):
				valid_positions.append(pos)
	
	if valid_positions.size() > 0:
		# Choose random position from valid positions
		var random_pos = valid_positions[randi() % valid_positions.size()]
		var world_pos = tilemap.map_to_local(random_pos)
		
		var bomb = bomb_scene.instantiate()
		bomb.global_position = world_pos
		bomb.explosion_range = bomb_range
		
		# Add cleanup for when bomb is removed
		bomb.tree_exiting.connect(func(): 
			current_bombs -= 1
			active_bomb_positions.erase(random_pos)
		)
		
		get_parent().add_child(bomb)
		current_bombs += 1
		active_bomb_positions.append(random_pos)

func die():
	if not is_alive:
		return
		
	is_alive = false
	velocity = Vector2.ZERO
	
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	queue_free()
