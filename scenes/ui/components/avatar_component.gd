extends Button
## Avatar selection component displaying a profile picture and name

@onready var picture: TextureRect = %Picture
@onready var name_label: Label = %NameLabel

## Stored texture path for retrieval
var texture_path: String = ""


func _ready() -> void:
    pass


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
