# game.gd
extends Node2D
@onready var map = $TileMap
@onready var music_player = $AudioStreamPlayer
var baloon_scene = preload("res://Scenes/Baloon.tscn")
var win_screen_scene = preload("res://Scenes/win_screen.tscn")
var background_music = preload("res://Sounds/amb.mp3")
var power_ups = [Vector2i(0,14), Vector2i(4,14), Vector2i(5,14)]
var power_ups_pos = []
var door_position: Vector2i  # Store door position

func _ready() -> void:
	$Player.pickup_power.connect(_on_player_pickup_power)
	var door_placed = false
	var valid_door_positions = []
	randomize();
	
	# First pass: collect valid positions for blocks
	for i in range(12):
		for j in range(30):
			var pos = Vector2i(j, i)
			
			# Skip player starting area
			if (i == 1 and j == 1) or (i == 1 and j == 2) or (i == 2 and j == 1):
				continue
			
			# Check if there's any tile on layer 2
			var existing_tile = map.get_cell_tile_data(2, pos)
			
			# Only place block if position is empty
			if existing_tile == null:
				var rand_val = randi_range(0, 100)
				if rand_val <= 1:
					# Store valid positions for door
					valid_door_positions.append(pos)
					# Place destructible block on layer 2
					map.set_cell(2, pos, 0, Vector2i(4, 3))
					
					# 10% chance for power-up under block
					if randi_range(0, 100) <= 100:
						# Randomly select one of the three power-up tiles
						var random_power_up = power_ups[randi() % power_ups.size()]
						map.set_cell(1, pos, 0, random_power_up)
						power_ups_pos.append(pos)
	
	# Place door under a random destructible block
	if valid_door_positions.size() > 0:
		door_position = valid_door_positions[randi() % valid_door_positions.size()]
		map.set_cell(1, door_position, 0, Vector2i(11, 3))
	spawn_baloons()

func _physics_process(_delta):
	check_win_condition()

func check_win_condition():
	var player = get_node("Player")
	if !player or !player.is_alive:
		return
		
	var player_pos = map.local_to_map(player.global_position)
	if player_pos == door_position:
		if are_all_baloons_defeated():
			show_win_screen()

func show_win_screen():
	var win_screen = win_screen_scene.instantiate()
	get_tree().root.add_child(win_screen)
	win_screen.layer = 100
	
	# Stop the player
	var player = get_node("Player")
	if player:
		player.has_won = true
		player.velocity = Vector2.ZERO

func spawn_baloons():
	var free_positions = []

	# Find free positions on the map
	for i in range(map.get_used_rect().size.y):
		for j in range(map.get_used_rect().size.x):
			var pos = Vector2i(j, i)
			
			# Check if position is empty on both layers
			var tile_data_1 = map.get_cell_tile_data(1, pos)
			var tile_data_2 = map.get_cell_tile_data(2, pos)
			
			if tile_data_1 == null and tile_data_2 == null:
				free_positions.append(pos)

	# Spawn between 5-6 balloons
	var baloon_count = randi_range(0,0)
	for k in range(baloon_count):
		if free_positions.size() == 0:
			break

		# Choose a random free position
		var random_index = randi() % free_positions.size()
		var baloon_pos = free_positions[random_index]
		free_positions.remove_at(random_index)  # Remove used position

		# Spawn the balloon
		var baloon = baloon_scene.instantiate()
		var world_pos = map.map_to_local(baloon_pos)
		baloon.position = world_pos
		add_child(baloon)

func are_all_baloons_defeated() -> bool:
	var baloons = get_tree().get_nodes_in_group("baloons")
	print("Number of balloons: ", baloons.size()) # Debug print
	return baloons.size() == 0
	
func _on_player_pickup_power(player_pos: Vector2i):
	if player_pos in power_ups_pos:
		var atlas_coords = map.get_cell_atlas_coords(1, player_pos)
		var player = get_node("Player")
		
		if atlas_coords == Vector2i(5, 14):  # Bomb range power-up
			player.bomb_range += 1
			map.erase_cell(1, player_pos)
			power_ups_pos.erase(player_pos)
		elif atlas_coords == Vector2i(0, 14):  # Additional bomb power-up
			player.max_bombs += 1
			map.erase_cell(1, player_pos)
			power_ups_pos.erase(player_pos)
		elif atlas_coords == Vector2i(4, 14):  # Random bomb ability power-up
			player.can_place_random_bombs = true
			map.erase_cell(1, player_pos)
			power_ups_pos.erase(player_pos)
