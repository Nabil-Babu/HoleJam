extends Control

const STEAM_APP_ID : int = 480 # 480 is dev app test ID... NEED TO REPLACE

@export var player_scene : PackedScene
@onready var lobby_ui: VBoxContainer = $LobbyUI
@onready var button_host: Button = $LobbyUI/Button_Host
@onready var button_join: Button = $LobbyUI/Button_Join
@onready var lobby_id_prompt: LineEdit = $LobbyUI/Lobby_ID_Prompt
@onready var boxes_container: Node3D = $Boxes
@onready var mp_box_spawner: MultiplayerSpawner = $Boxes/MP_BoxSpawner

var peer : SteamMultiplayerPeer
var join_code : String
var is_joining := false
var local_lobby_id : int = 0
var boxCount: int = 0
var box_scene: PackedScene = preload("res://scenes/box.tscn")

func _ready() -> void: 
	check_lobby_prompt()
	var steam_init := Steam.steamInit(STEAM_APP_ID, true)
	if steam_init:
		print("Steam Initialization OK")
		Steam.initRelayNetworkAccess()
		Steam.lobby_joined.connect(_lobby_joined)
		Steam.lobby_created.connect(_lobby_created)
		Steam.lobby_match_list.connect(_check_lobby_list)
	else:
		print("Steam did not initialize :(")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func _lobby_joined(lobby_id : int, _permissions : int, _locked : bool, _response : int) -> void:
	if not is_joining:
		return
	local_lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	peer.connect_to_lobby(lobby_id)
	multiplayer.multiplayer_peer = peer
	is_joining = false


# should only run on the host machine (via host button)
func _lobby_created(result : int, lobby_id : int):
	if result == Steam.Result.RESULT_OK:
		local_lobby_id = lobby_id
		print("Steam Lobby created OK")
		print("Steam lobby id : " + str(lobby_id))
		join_code = lobby_id_prompt.text
		#join_code = str(randi() % 100000).pad_zeros(5)
		Steam.setLobbyData(lobby_id, "join_code", join_code)
		
		# creating host and lobby
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		print("Lobby created with code: " + str(join_code))
		
		# bind this to Godot's internal mp system
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)
		add_player() # adding host as player, default id = 1


func _check_lobby_list(lobbies : Array) -> void:
	for lobby in lobbies:
		var code = Steam.getLobbyData(lobby, "join_code")
		if code == join_code:
			Steam.joinLobby(lobby)
			is_joining = true
			return
	print("No lobbies found with specified Join Code: " + str(join_code))


func add_player(id : int = 1):
#	if id == 1:
#		lobby_ui.hide()
#	else:
#		send_disable_lobby_ui_request(id)
	send_disable_lobby_ui_request(id)
	var player: Node = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	print("Player joined with ID: " + str(id))


func remove_player(id : int) -> void:
	if not self.has_node(str(id)):
		return
	self.get_node(str(id)).queue_free()
	print("Player left with ID: " + str(id))


func spawn_box() -> void:
	if not multiplayer.is_server():
		return
	boxCount += 1
	var box: Node = box_scene.instantiate()
	box.set_multiplayer_authority(1) # set to server id = 1
	box.name = "BOX_" + str(boxCount) + "_" + str(local_lobby_id)
	#boxes_container.add_child(box, true)
	#box.position = global_pos
	
	boxes_container.call_deferred("add_child", box, true)
	# box.set_deferred("global_position", global_pos)


func check_lobby_prompt():
	button_join.disabled = (lobby_id_prompt.text.length() == 0)
	button_host.disabled = (lobby_id_prompt.text.length() == 0)
	join_code = lobby_id_prompt.text

################################################################################
######## RPC Functions ########
################################################################################

# "authority" means only the server/master can call this on peers.
# "reliable" ensures the message packet is guaranteed to arrive.
@rpc("authority", "call_remote", "reliable")
func receive_message_from_server(message: String):
	# This code executes on the client machine
	print("Received from server: ", message)


func send_data_to_single_client(client_id: int, text_to_send: String):
	# The first argument is the destination peer ID.
	# Any subsequent arguments are passed into the target function.
	receive_message_from_server.rpc_id(client_id, text_to_send)


func send_data_to_all_clients(text_to_send: String):
	receive_message_from_server.rpc(text_to_send)


@rpc("authority", "call_local", "reliable")
func receive_disable_lobby_ui_request():
	lobby_ui.hide()


func send_disable_lobby_ui_request(client_id: int):
	receive_disable_lobby_ui_request.rpc_id(client_id)

################################################################################
######## Singals from Node Children ########
################################################################################

func _on_button_host_pressed() -> void:
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 8) # define max players


func _on_button_join_pressed() -> void:
	join_code = lobby_id_prompt.text
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()


func _on_lobby_id_prompt_text_changed(new_text: String) -> void:
	button_join.disabled = (new_text.length() == 0)
	button_host.disabled = (new_text.length() == 0)
	join_code = new_text
