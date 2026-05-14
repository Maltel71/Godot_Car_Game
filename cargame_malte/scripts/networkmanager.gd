extends Node2D

const PORT = 7000
@export var player_scene: PackedScene

func _ready():
	# Connection feedback — tells us what's actually happening
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	if multiplayer.is_server():
		multiplayer.peer_connected.connect(add_player)

func _on_host_pressed():
	host_game()

func _on_join_pressed():
	var ip = $Control/GridContainer/IPField.text.strip_edges()
	if ip.is_empty():
		print("Enter the host's Tailscale IP first")
		return
	print("Attempting to join ", ip, ":", PORT)
	join_game(ip)

func host_game():
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT)
	if err != OK:
		print("Failed to create server: ", err)
		return
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_connected.is_connected(add_player):
		multiplayer.peer_connected.connect(add_player)
	add_player(1)
	print("Server started on port ", PORT)

func join_game(ip_address: String):
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip_address, PORT)
	if err != OK:
		print("Failed to create client: ", err)
		return
	multiplayer.multiplayer_peer = peer

func _on_connected():
	print("Successfully connected to server!")

func _on_connection_failed():
	print("Connection failed — could not reach the host.")

func _on_server_disconnected():
	print("Disconnected from server.")

func add_player(id: int):
	if not multiplayer.is_server():
		return
	print("Peer connected, spawning player: ", id)
	var player = player_scene.instantiate()
	player.name = str(id)
	$SpawnPoint.add_child(player)
	player.set_multiplayer_authority(id)
