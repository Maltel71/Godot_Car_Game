extends Node2D

const PORT = 7000
@export var player_scene: PackedScene

func _ready():
	# Only the server should listen for new peers and spawn players.
	# peer_connected fires on clients too, which would cause ghost duplicates.
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(add_player)

func host_game():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	# Re-check after becoming server, since _ready already ran before the peer was set.
	if not multiplayer.peer_connected.is_connected(add_player):
		multiplayer.peer_connected.connect(add_player)
	add_player(1) # 1 is always the Host ID

func join_game(ip_address: String = "127.0.0.1"):
	# Replace with the Host's actual local IP address
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, PORT)
	multiplayer.multiplayer_peer = peer

func add_player(id: int):
	# Safety guard: only the server spawns players. The MultiplayerSpawner
	# will replicate the spawn to all connected clients automatically.
	if not multiplayer.is_server():
		return

	var player = player_scene.instantiate()
	player.name = str(id)
	$SpawnPoint.add_child(player)

	# Give controls to the specific player who joined
	player.set_multiplayer_authority(id)
