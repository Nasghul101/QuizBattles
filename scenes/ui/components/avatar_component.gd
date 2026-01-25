extends Button
## Avatar selection component displaying a profile picture and name

@onready var picture: TextureRect = %Picture
@onready var name_label: Label = %NameLabel


func _ready() -> void:
    pass


## Set the avatar picture texture from a resource path
func set_avatar_picture(texture_path: String) -> void:
    var texture: Texture2D = load(texture_path)
    if texture:
        picture.texture = texture


## Set the avatar name label text
func set_avatar_name(name: String) -> void:
    name_label.text = name
