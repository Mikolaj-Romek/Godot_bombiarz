extends Node2D
@onready var map = $TileMap

func _ready() -> void:
	var door_placed = false
	var valid_door_positions = []
	
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
