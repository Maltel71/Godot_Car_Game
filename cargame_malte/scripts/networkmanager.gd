extends Node2D

const PORT = 7000
@export var player_scene: PackedScene

func _ready():
	# Runs on the server when a new client connects
	multiplayer.peer_connected.connect(add_player)

func host_game():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	add_player(1) # 1 is always the Host ID

func join_game(ip_address: String = "192.168.1.50"): 
	# Replace with the Host's actual local IP address
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, PORT)
	multiplayer.multiplayer_peer = peer

func add_player(id: int):
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)
	
	# Move the player to your SpawnPoint's position
	player.global_position = $SpawnPoint.global_position
