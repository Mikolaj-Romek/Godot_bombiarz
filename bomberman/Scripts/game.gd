extends Node2D
@onready var map = $TileMap
var baloon_scene = preload("res://Scenes/Baloon.tscn") 
var power_ups = [Vector2i(0,14), Vector2i(4,14), Vector2i(5,14)]
var power_ups_pos = []

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
				if rand_val <= 20:
					# Store valid positions for door
					valid_door_positions.append(pos)
					# Place destructible block on layer 2
					map.set_cell(2, pos, 0, Vector2i(4, 3))
					
					# 10% chance for power-up under block
					if randi_range(0, 100) <= 55:
						# Randomly select one of the three power-up tiles
						var random_power_up = power_ups[randi() % power_ups.size()]
						map.set_cell(1, pos, 0, random_power_up)
						power_ups_pos.append(pos)
	
	# Place door under a random destructible block
	if valid_door_positions.size() > 0:
		var door_pos = valid_door_positions[randi() % valid_door_positions.size()]
		map.set_cell(1, door_pos, 0, Vector2i(11, 3))
	spawn_baloons()

func spawn_baloons():
	var free_positions = []

	# Find free positions on the map
	for i in range(map.get_used_rect().size.y):
		for j in range(map.get_used_rect().size.x):
			var pos = Vector2i(j, i)
			
			# Check if position is empty on layer 2
			if map.get_cell_tile_data(1, pos) == null:
				free_positions.append(pos)

	# Spawn between 5-10 balloons
	var baloon_count = randi_range(10, 20)
	for k in range(baloon_count):
		if free_positions.size() == 0:
			break

		# Choose a random free position
		var random_index = randi() % free_positions.size()
		var baloon_pos = free_positions[random_index]

		# Spawn the balloon
		var baloon = baloon_scene.instantiate()
		var world_pos = map.map_to_local(baloon_pos)
		baloon.position = world_pos
		add_child(baloon)

func _on_player_pickup_power(player_pos: Vector2i):
	if player_pos in power_ups_pos:
		var atlas_coords = map.get_cell_atlas_coords(1, player_pos)
		if atlas_coords == Vector2i(0, 14):  # Bomb range power-up
			var player = get_node("Player")
			player.bomb_range += 1
			map.erase_cell(1, player_pos)
			power_ups_pos.erase(player_pos)
