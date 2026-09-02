extends CharacterBody2D

enum State { IDLE, CHASING, ATTACKING }

@export var speed: float = 150.0
@export var attack_cooldown: float = 1.0
@export var player_path: NodePath = "../Player"
@export var vision_area_path: NodePath = "VisionArea2D"  # relative to player

@onready var alert_range_area: Area2D = $AlertRangeArea2D
@onready var attack_range_area: Area2D = $AttackRangeArea2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var vision_area: Area2D = get_node(player_path).get_node(vision_area_path)

var _space_state: PhysicsDirectSpaceState2D
var _state: State = State.IDLE
var _player: CharacterBody2D = null
var _player_in_attack_range: bool = false
var _attack_timer: float = 0.0

func _ready() -> void:
	_space_state = get_world_2d().direct_space_state
	alert_range_area.body_entered.connect(_on_alert_range_area_body_entered)
	alert_range_area.body_exited.connect(_on_alert_range_area_body_exited)
	attack_range_area.body_entered.connect(_on_attack_range_area_body_entered)
	attack_range_area.body_exited.connect(_on_attack_range_area_body_exited)
	sprite.visible = false
	vision_area.body_entered.connect(_on_vision_area_body_entered)
	vision_area.body_exited.connect(_on_vision_area_body_exited)

func _physics_process(delta: float) -> void:
	var previous_state := _state
	_update_state()
	if _state == State.ATTACKING and previous_state != State.ATTACKING:
		_attack_timer = 0.0

	match _state:
		State.CHASING:
			velocity = global_position.direction_to(_player.global_position) * speed
			move_and_slide()
		State.ATTACKING:
			velocity = Vector2.ZERO
			_attack_timer -= delta
			if _attack_timer <= 0.0:
				_attack_timer = attack_cooldown
				print("attack")
		State.IDLE:
			velocity = Vector2.ZERO

func _update_state() -> void:
	if _player == null:
		_state = State.IDLE
	elif _player_in_attack_range:
		_state = State.ATTACKING
	elif _has_line_of_sight():
		_state = State.CHASING
	else:
		_state = State.IDLE

func _has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(
		global_position, _player.global_position, 1  # mask = 1, matches walls' physics_layer_0/collision_layer
	)
	query.exclude = [get_rid()]
	var result := _space_state.intersect_ray(query)
	return result.is_empty()

func _on_alert_range_area_body_entered(body: Node2D) -> void:
	_player = body as CharacterBody2D

func _on_alert_range_area_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null

func _on_attack_range_area_body_entered(_body: Node2D) -> void:
	_player_in_attack_range = true

func _on_attack_range_area_body_exited(_body: Node2D) -> void:
	_player_in_attack_range = false

func _on_vision_area_body_entered(body: Node2D) -> void:
	if body == self:
		sprite.visible = true

func _on_vision_area_body_exited(body: Node2D) -> void:
	if body == self:
		sprite.visible = false
