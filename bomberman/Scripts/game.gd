extends Node2D
@onready var map = $TileMap
var baloon_scene = preload("res://Scenes/Baloon.tscn") 

func _ready() -> void:
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
					if randi_range(0, 100) <= 10:
						# Randomly select one of the three power-up tiles
						var power_ups = [Vector2i(0,14), Vector2i(4,14), Vector2i(5,14)]
						var random_power_up = power_ups[randi() % power_ups.size()]
						map.set_cell(1, pos, 0, random_power_up)
	
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
	print("Spawning", baloon_count, "balloons")
	for k in range(baloon_count):
		if free_positions.size() == 0:
			break

		# Choose a random free position
		var random_index = randi() % free_positions.size()
		var baloon_pos = free_positions[random_index]
		#free_positions.remove(random_index)  # Prevent duplicate positions

		# Spawn the balloon
		var baloon = baloon_scene.instantiate()
		var world_pos = map.map_to_local(baloon_pos)  # Convert tile position to world position
		baloon.position = world_pos
		add_child(baloon)

		print("Spawned balloon at tile position:", baloon_pos, "world position:", world_pos)
