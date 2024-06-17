class_name Player
extends CharacterBody2D


@export_category("Movement")
@export var speed: float = 3

@export_category("Life")
@export var health: int = 100
@export var max_health: int = 100
@export var death_prefab: PackedScene

@export_category("Sword")
@export var sword_damage: int = 2

@export_category("Ritual")
@export var ritual_damage: int = 1
@export var ritual_interval: float = 30
@export var ritual_scene: PackedScene


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar

var input_vector: Vector2 = Vector2(0,0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var ritual_cooldown: float = 0.0
var current_attack = 1
var attack_direction_vector: Vector2 = Vector2.RIGHT
var knockback_strength: float = 20
var knockback_strength_caps: float = 50

signal meat_collected(value: int)
signal gold_collected(value: int)

func _ready():
	GameManager.player = self
	gold_collected.connect(func(value: int):
		GameManager.gold_counter += 1
	)

func _process(delta):
	GameManager.player_position = position
	
	read_input()
	
	# Atualizar temporizador do ataque
	update_attack_cooldown(delta)
	if Input.is_action_just_pressed("attack"):
		attack()
	
	attack_direction_vector = attack_direction()
	
	# Tocar animacao
	play_run_idle_animation()
	if not is_attacking:
		# Girar sprite
		rotate_sprite()
	
	# Ataque
	if Input.is_action_just_pressed("attack"):
		attack()
	
	# Processar dano
	update_hitbox_detection(delta)
	
	# Ritual
	update_ritual(delta)
	
	# Atualizar health bar
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health

func _physics_process(delta):
	# Modificar a velocidade
	var target_velocity = input_vector * speed * 100.0
	if is_attacking:
		target_velocity *= 0.25
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()

func update_attack_cooldown(delta):
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")

func read_input():
	# Obter o input vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.15)
	
	# Apagar deadzone do input vector (para controles de videogame)
	var deadzone = 0.15
	if abs(input_vector.x) < 0.15:
		input_vector.x = 0.0
	if abs(input_vector.y) < 0.15:
		input_vector.y = 0.0
	
	# Atualizar o is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx()

func play_run_idle_animation():
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")

func rotate_sprite():
	# Desmarcar flip_h do Sprite2D
	if input_vector.x > 0:
		sprite.flip_h = false
	elif input_vector.x < 0:
		sprite.flip_h = true

func attack():
	if is_attacking:
		return
	
	# Tocar animação
	if input_vector.y < 0:
		animation_player.play("attack_up_" + str(current_attack%2+1))
	elif input_vector.y > 0:
		animation_player.play("attack_down_" + str(current_attack%2+1))
	else:
		animation_player.play("attack_side_" + str(current_attack%2+1))
	
	current_attack += 1
	
	# Configurar temporizador
	attack_cooldown = 0.6
	
	# Marcar ataque
	is_attacking = true

func deal_damage_to_enemies():
	# Acessar inimigos que estão na área de dano
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var direction_to_enemy = (enemy.position - position).normalized()
			
			var dot_product = direction_to_enemy.dot(attack_direction_vector)
			if dot_product > 0:
				# Chamar a funcao damage com sword_damage como parametro
				sword_damage = randi_range(1,5)
				enemy.damage(sword_damage)
				enemy.knockback(knockback_strength)

func attack_direction() -> Vector2:
	var direction : Vector2 = Vector2.ZERO
	var attack_angle = rad_to_deg(input_vector.angle())
	var attack_horizontal = abs(attack_angle)
	
	if attack_horizontal <= 45 or attack_horizontal >= 135:
		if sprite.flip_h:
			direction = Vector2.LEFT
		else:
			direction = Vector2.RIGHT
	elif attack_angle > 45 and attack_angle < 135:
		direction = Vector2.DOWN
	else:
		direction = Vector2.UP
	return direction

func update_hitbox_detection(delta: float):
	# Temporizador
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return 
	
	# Frequencia
	hitbox_cooldown = 0.5
	
	# Detectar inimigos
	var bodies = hitbox_area.get_overlapping_bodies() 
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			var damage_amount = 1
			damage(damage_amount)

#func is_knockback_strength_caps() -> bool:
	#if knockback_strength >= knockback_strength_caps: return true
	#else: return false

func damage(amount: int):
	if health <= 0:
		return
	
	health -= amount
	print("Player recebeu dano de ", amount, ". A vida total é de ", health, "/", max_health)
	
	# Piscar node
	modulate = Color.RED
	# Suavizacao da transicao da cor
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Processar morte
	if health <= 0:
		die()

func die():
	GameManager.end_game()
	
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		# Registra o objeto na cena
		get_parent().add_child(death_object)
	
	queue_free()

func heal(amount: int):
	health += amount
	if health > max_health:
		health = max_health
	print("Player recebeu cura de ", amount, ". A vida total é de ", health, "/", max_health)
	return health

func update_ritual(delta: float):
	# Atualizar temporizador
	ritual_cooldown -= delta
	if ritual_cooldown > 0: return
	
	# Resetar temporizador
	ritual_cooldown = ritual_interval
	
	# Criar ritual
	var ritual = ritual_scene.instantiate()
	add_child(ritual) # Colocar o ritual no player
	ritual.damage_amount = ritual_damage

