extends Node2D

@export var regeneration_amount: int = 10

func _ready():
	# Emite quando um corpo entra nessa área e recebe ele como parametro
	$Area2D.body_entered.connect(on_body_entered)

func on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		var player: Player = body
		player.heal(regeneration_amount)
		# Chama o signal e emite
		player.meat_collected.emit(regeneration_amount)
		# Deleta objeto
		queue_free()
