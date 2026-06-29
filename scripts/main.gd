extends Control

const STEAM_APP_ID : int = 480 # 480 is dev app test ID... NEED TO REPLACE
signal game_started

@export var player_scene : PackedScene
@export var game_score: int = 0

@onready var lobby_ui: PanelContainer = $LobbyUI
@onready var jelly_score_ui: Label3D = $"Score UI/JellyScoreUI"
@onready var robot_score_ui: Label3D = $"Score UI/RobotScoreUI"
@onready var button_host: Button = $LobbyUI/Margins/VBox/Button_Host
@onready var button_join: Button = $LobbyUI/Margins/VBox/Button_Join
@onready var lobby_id_prompt: LineEdit = $LobbyUI/Margins/VBox/HBoxContainer/Lobby_ID_Prompt

@onready var player_container: Node3D = $MP_PlayerSpawner/PlayerContainer
@onready var mp_box_spawner: MultiplayerSpawner = $MP_BoxSpawner
@onready var box_container: Node3D = $MP_BoxSpawner/BoxContainer

var peer : SteamMultiplayerPeer
var join_code : String
var is_joining := false
var local_lobby_id : int = 0
var boxCount: int = 0
var box_spawn_markers : Array[Node]
var player_spawn_markers : Array[Node]
var box_scene: PackedScene = preload("res://scenes/box.tscn")
var game_scores: Dictionary[String, int] = {"JELLIES": 0, "ROBOTS": 0}

func _ready() -> void: 
	box_spawn_markers = box_container.get_children()
	player_spawn_markers = player_container.get_children()
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
	# Ignore the ERROR this creates
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
		# Ignore the ERROR this creates
		peer.connect_to_lobby(lobby_id)
		print("Lobby created with code: " + str(join_code))
		
		# bind this to Godot's internal mp system
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)
		add_player() # adding host as player, default id = 1
		game_started.emit()


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
	player_container.call_deferred("add_child", player, true)
	if multiplayer.is_server() && id != 1:
		for team: String in game_scores.keys():
			receive_team_score.rpc_id(id, team, game_scores[team])
	print("Player joined with ID: " + str(id))
	
	if player_spawn_markers.size() > 0:
		var index: int = randi() % player_spawn_markers.size()
		var player_pos: Vector3 = player_spawn_markers[index].global_position
		var player_path: NodePath = NodePath(str(player_container.get_path()) + "/" + str(player.name))
		set_player_spawn_pos.rpc.call_deferred(player_pos, player_path)


func remove_player(id : int) -> void:
	if not self.has_node(str(id)):
		return
	self.get_node(str(id)).queue_free()
	print("Player left with ID: " + str(id))


func spawn_box() -> void:
	if not multiplayer.is_server():
		return
	if boxCount >= mp_box_spawner.spawn_limit:
		#print("Already too many boxes in the FACTORY")
		return
	boxCount += 1
	var box: Node = box_scene.instantiate()
	box.set_multiplayer_authority(1) # set to server id = 1
	box.box_despawn.connect(box_despawned)
	box.name = "BOX_" + str(boxCount) + "_" + str(local_lobby_id)
	box_container.call_deferred("add_child", box, true)
	
	if box_spawn_markers.size() > 0:
		var index: int = randi() % box_spawn_markers.size()
		var box_pos: Vector3 = box_spawn_markers[index].global_position
		var box_path: NodePath = NodePath(str(box_container.get_path()) + "/" + str(box.name))
		set_box_spawn_pos.rpc.call_deferred(box_pos, box_path)


func box_despawned():
	#print("Satan will despawn you little box <3")
	boxCount -= 1


func check_lobby_prompt():
	button_join.disabled = (lobby_id_prompt.text.length() == 0)
	button_host.disabled = (lobby_id_prompt.text.length() == 0)
	join_code = lobby_id_prompt.text

################################################################################
######## RPC Functions ########
################################################################################
# "authority" means only the server/master can call this on peers.
# "reliable" ensures the message packet is guaranteed to arrive.

@rpc("any_peer", "call_local", "reliable")
func set_box_spawn_pos(taret_pos: Vector3, path : NodePath):
	var box: Node = get_node(path)
	if box:
		box.global_position = taret_pos

@rpc("any_peer", "call_local", "reliable")
func set_player_spawn_pos(taret_pos: Vector3, path : NodePath):
	var player: Node = get_node(path)
	if player:
		player.global_position = taret_pos

@rpc("authority", "call_remote", "reliable")
func receive_message_from_server(message: String):
	# This code executes on the client machine
	print("Received from server: ", message)


@rpc("any_peer", "call_local", "reliable")
func update_team_score(team: String, new_score: int) -> void:
	if !multiplayer.is_server():
		return
	if game_scores.has(team):
		game_scores[team]+=new_score
		if(game_scores[team] < 0): 
			game_scores[team] = 0
		update_team_ui(team)
		receive_team_score.rpc(team, game_scores[team])

@rpc("any_peer", "call_local", "reliable")	
func request_team_score(team: String) -> void:
	if multiplayer.is_server() && game_scores.has(team):
		var id: int = multiplayer.get_remote_sender_id()
		receive_team_score.rpc_id(id, team, game_scores[team])

@rpc("authority", "call_remote", "reliable")
func receive_team_score(team: String, score: int):
	game_scores[team] = score;
	update_team_ui(team)
	
@rpc("authority", "call_local", "reliable")
func receive_disable_lobby_ui_request():
	lobby_ui.hide()

func update_team_ui(team: String) -> void:
	if team == "JELLIES":
		jelly_score_ui.text = "Jellies: " + str(game_scores["JELLIES"])
	if team == "ROBOTS":
		robot_score_ui.text = "Robots: " + str(game_scores["ROBOTS"])

func send_data_to_single_client(client_id: int, text_to_send: String):
	# The first argument is the destination peer ID.
	# Any subsequent arguments are passed into the target function.
	receive_message_from_server.rpc_id(client_id, text_to_send)


func send_data_to_all_clients(text_to_send: String):
	receive_message_from_server.rpc(text_to_send)


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
