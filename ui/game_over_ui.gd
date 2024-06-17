class_name GameOverUI
extends CanvasLayer


@onready var time_label: Label = %TimeLabel
@onready var monsters_label: Label = %MonstersLabel
@onready var countdown_label: Label = %Restarting


@export var restart_delay: float = 5.0
var restart_cooldown: float


func _ready():
	time_label.text = GameManager.time_elapsed_string
	monsters_label.text = str(GameManager.monsters_defeated_counter)
	restart_cooldown = restart_delay


func _process(delta):
	updateCountdownLabel()
	restart_cooldown -= delta
	if restart_cooldown <= 0.0:
		restart_game()


func restart_game():
	GameManager.reset()
	get_tree().reload_current_scene()

func updateCountdownLabel():
	var countdown: int = ceili(restart_cooldown) % 60
	countdown_label.text = "Restarting in %d seconds..." % countdown

func _input(event):
	if event.is_action_pressed("return"):
		restart_cooldown = 0
