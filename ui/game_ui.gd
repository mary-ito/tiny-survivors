extends CanvasLayer

@onready var timer_label: Label = %TimerLabel
@onready var gold_label: Label = %GoldLabel
@onready var dead_label: Label = %DeadLabel


func _process(delta: float):
	# Update labels
	timer_label.text = GameManager.time_elapsed_string
	gold_label.text = str(GameManager.gold_counter)
	dead_label.text = str(GameManager.monsters_defeated_counter)
