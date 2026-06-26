extends Control

const STEAM_APP_ID : int = 480 # 480 is dev app test ID... NEED TO REPLACE

@export var player_scene : PackedScene
@onready var lobby_ui = $LobbyUI
@onready var button_host: Button = $LobbyUI/Button_Host
@onready var button_join: Button = $LobbyUI/Button_Join
@onready var lobby_id_prompt: LineEdit = $LobbyUI/Lobby_ID_Prompt
@onready var players: Node2D = $Players

var peer : SteamMultiplayerPeer
var join_code : String
var is_joining := false
var lobby_id : int = 0


func _ready() -> void: 
	var steam_init := Steam.steamInit(STEAM_APP_ID, true)
	if steam_init:
		print("Steam Initialization OK")
		Steam.initRelayNetworkAccess()
		Steam.lobby_joined.connect(_lobby_joined)
		Steam.lobby_created.connect(_lobby_created)
		Steam.lobby_match_list.connect(_check_lobby_list)
	else:
		print("Steam did not initialize :(")


func _lobby_joined(lobby_id : int, _permissions : int, _locked : bool, _response : int):
	if not is_joining:
		return
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	peer.connect_to_lobby(lobby_id)
	multiplayer.multiplayer_peer = peer
	#multiplayer.peer_connected.connect(add_player)
	#multiplayer.peer_disconnected.connect(remove_player)
	is_joining = false


# should only run on the host machine (via host button)
func _lobby_created(result : int, lobby_id : int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		print("Steam Lobby created OK")
		print("Steam lobby id : " + str(lobby_id))
		join_code = lobby_id_prompt.text
		#join_code = str(randi() % 100000).pad_zeros(5)
		Steam.setLobbyData(lobby_id, "join_code", join_code)
		
		# creating host and lobby
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		peer.connect_to_lobby(lobby_id)
		print("Lobby created with code: " + str(join_code))
		
		# bind this to Godot's internal mp system
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)
		add_player() # adding host as player, default id = 1


func _check_lobby_list(lobbies : Array):
	for lobby in lobbies:
		var code = Steam.getLobbyData(lobby, "join_code")
		if code == join_code:
			Steam.joinLobby(lobby)
			is_joining = true
			return
	print("No lobbies found with specified Join Code: " + str(join_code))


func add_player(id : int = 1):
	lobby_ui.hide() # doesnt remove for other player
	var player = player_scene.instantiate()
	player.name = str(id)
	players.call_deferred("add_child", player)
	print("Player joined with ID: " + str(id))


func remove_player(id : int):
	if not self.has_node(str(id)):
		return
	self.get_node(str(id)).queue_free()
	print("Player left with ID: " + str(id))


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
