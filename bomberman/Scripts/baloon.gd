extends CharacterBody2D

const SPEED = 50.0
var direction: Vector2 = Vector2.ZERO
var is_alive = true
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var music_player = $AudioStreamPlayer
var pain_sound = preload("res://Sounds/pain.mp3")
var change_direction_timer = 0.0
const DIRECTION_CHANGE_TIME = 3.0
var pain_duration

func _ready():
	add_to_group("player")
	choose_random_direction()
	music_player.stream = pain_sound
	pain_duration = music_player.stream.get_length() - 5

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	change_direction_timer += delta
	if change_direction_timer >= DIRECTION_CHANGE_TIME:
		choose_random_direction()
		change_direction_timer = 0.0

	velocity = direction * SPEED
	
	var collision = move_and_collide(velocity * delta, true)
	if collision:
		if collision.get_collider() is StaticBody2D and collision.get_collider().get_parent() is Area2D:
			direction = -direction
			change_direction_timer = DIRECTION_CHANGE_TIME
		else:
			choose_random_direction_avoiding_collision()
	else:
		move_and_slide()

	if sprite.animation != "default" and is_alive:
		sprite.play("default")

func choose_random_direction():
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	direction = directions[randi() % directions.size()]

func choose_random_direction_avoiding_collision():
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	directions.shuffle()
	
	for dir in directions:
		var test_velocity = dir * SPEED
		var collision = move_and_collide(test_velocity * 0.1, true)
		if not collision:
			direction = dir
			return
	
	direction = Vector2.ZERO

func die():
	if not is_alive:
		return

	is_alive = false
	velocity = Vector2.ZERO

	sprite.play("die")
	music_player.seek(pain_duration)
	music_player.play()
	sprite.animation_finished.connect(func():
		queue_free())
