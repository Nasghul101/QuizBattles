extends Button
## Avatar selection component displaying a profile picture and name

## Emitted when the avatar button is clicked, passes the user_id
signal avatar_clicked(user_id: String)

@onready var picture: TextureRect = %Picture
@onready var name_label: Label = %NameLabel

## Stored texture path for retrieval
var texture_path: String = ""

## Stored user ID for this avatar
var user_id: String = ""

## Match ID for multiplayer navigation
var match_id: String = ""


func _ready() -> void:
    pressed.connect(_on_avatar_pressed)


## Set the avatar picture texture from a resource path
func set_avatar_picture(texture_path_param: String) -> void:
    texture_path = texture_path_param
    var texture: Texture2D = load(texture_path)
    if texture:
        picture.texture = texture


## Set the avatar name label text
func set_avatar_name(custom_name: String) -> void:
    name_label.text = custom_name


## Get the stored avatar texture path
func get_avatar_path() -> String:
    return texture_path


## Set the user ID for this avatar
func set_user_id(id: String) -> void:
    user_id = id


## Get the stored user ID
func get_user_id() -> String:
    return user_id


## Store match identifier for multiplayer navigation
##
## @param id: Match ID string
func set_match_id(id: String) -> void:
    match_id = id


## Handle avatar button press - emit avatar_clicked signal
func _on_avatar_pressed() -> void:
    if not user_id.is_empty():
        avatar_clicked.emit(user_id)
    elif not match_id.is_empty():
        avatar_clicked.emit(match_id)
