extends Node2D

@onready var spawn_positions: Node2D = $SpawnPositions
@onready var players: Node = $Players

const PLAYER_SCENE = preload("res://scenes/player.tscn")
var match_finished: bool = false

func _ready() -> void:
	NetworkManager.all_in_game.connect(_spawn_all)
	NetworkManager.rpc_id(1, "request_set_self_in_game", true)

func _spawn_all():
	if multiplayer.is_server():
		for player in NetworkManager.players:
			var player_instance = PLAYER_SCENE.instantiate()
			player_instance.name = str(player)
			var spawn_points = spawn_positions.get_children()
			if spawn_points.size() > 0:
				var rand_pos = spawn_points.pick_random()
				player_instance.position = rand_pos.position
				rand_pos.get_parent().remove_child(rand_pos)
				rand_pos.queue_free()
			players.add_child(player_instance)
			player_instance.died.connect(_on_player_died)
		
func add_score(score: int, shooter_id: int) -> void:
	for player in players.get_children():
		if player.name.to_int() == shooter_id:
			player.add_score(score)

func _on_player_died(player_id: int) -> void:
        print(players.get_children())
        var alive_players = []
        for p in players.get_children():
                if not p.dead:
                        alive_players.append(p)
       if alive_players.size() == 1 and not match_finished:
               match_finished = true
               var winner_id = alive_players[0].name.to_int()
               print("Only one player is alive: ", alive_players[0].name)
               NetworkManager.record_match_result(winner_id)
	
