extends Area2D

@onready var timer: Timer = $Timer
@onready var animated_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var music_player = $AudioStreamPlayer
var brick_scene = preload("res://Scenes/Brick.tscn")
var explosion_areas = []
var player_that_placed_bomb: Node = null
var collision_enabled = false
var explosion_range = 1

func _ready():
	timer.start()
	timer.timeout.connect(_on_timer_timeout)
	
	player_that_placed_bomb = get_tree().get_nodes_in_group("player")[0]
	static_body.set_collision_layer_value(1, false)
	
	body_exited.connect(_on_body_exited)

func _on_body_exited(body: Node):
	if body == player_that_placed_bomb and !collision_enabled:
		collision_enabled = true
		static_body.set_collision_layer_value(1, true)

func _physics_process(_delta):
	if animated_player.animation == "Boom":
		var overlapping_bodies = get_overlapping_bodies()
		for body in overlapping_bodies:
			if body is CharacterBody2D and body.has_method("die"):
				body.die()

func _on_timer_timeout():
	static_body.queue_free()
	
	var tilemap = get_parent().get_node("TileMap")
	var bomb_pos = tilemap.local_to_map(global_position)
	
	music_player.play()
	animated_player.play("Boom")
	
	var directions = {
		Vector2i(1, 0): ["Boom_right", "Boom_right_end"],
		Vector2i(-1, 0): ["Boom_left", "Boom_left_end"],
		Vector2i(0, 1): ["Boom_down", "Boom_down_end"],
		Vector2i(0, -1): ["Boom_up", "Boom_up_end"]
	}
	
	for dir in directions.keys():
		var current_range = 0
		var current_pos = bomb_pos
		var should_stop = false
		
		while current_range < explosion_range and !should_stop:
			current_pos = current_pos + dir
			var tile_data = tilemap.get_cell_tile_data(2, current_pos)
			
			if tile_data != null:
				var atlas_coords = tilemap.get_cell_atlas_coords(2, current_pos)
				if atlas_coords == Vector2i(4, 3):
					tilemap.erase_cell(2, current_pos)
					spawn_brick_destruction(current_pos)
					should_stop = true
				else:
					should_stop = true
			else:
				var animation_name = directions[dir][0] if current_range < explosion_range - 1 else directions[dir][1]
				create_explosion_area(current_pos, animation_name)
			
			current_range += 1
	
	animated_player.animation_finished.connect(func(): queue_free())

func create_explosion_area(pos: Vector2i, animation_name: String):
	var explosion = Area2D.new()
	var sprite = AnimatedSprite2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Setup collision
	shape.size = Vector2(16, 16)
	collision.shape = shape
	explosion.add_child(collision)
	
	# Setup sprite
	sprite.sprite_frames = animated_player.sprite_frames
	sprite.play(animation_name)
	
	explosion.add_child(sprite)
	get_parent().add_child(explosion)
	
	var tilemap = get_parent().get_node("TileMap")
	explosion.global_position = tilemap.map_to_local(pos)
	
	# Add collision detection for both initial and continuous contact
	explosion.body_entered.connect(func(body):
		if body is CharacterBody2D and body.has_method("die"):
			body.die()
	)
	
	# Check for bodies already in the area
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, explosion.global_position)
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result["collider"]
		if body is CharacterBody2D and body.has_method("die"):
			body.die()
	
	explosion_areas.append(explosion)
	sprite.animation_finished.connect(func(): 
		explosion_areas.erase(explosion)
		explosion.queue_free()
	)

func spawn_brick_destruction(pos: Vector2i):
	var brick = brick_scene.instantiate()
	get_parent().add_child(brick)
	
	var tilemap = get_parent().get_node("TileMap")
	brick.global_position = tilemap.map_to_local(pos)
	
	var animated_sprite = brick.get_node("AnimatedSprite2D")
	animated_sprite.play("default")
	animated_sprite.animation_finished.connect(func(): brick.queue_free())
