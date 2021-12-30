extends Control



# Called when the node enters the scene tree for the first time.
func _ready():
	# Access the "country_menu" PopupMenu through this.
	var menu_list_popup: PopupMenu = get_node("MenuButton").get_popup()
	# Signal for when the user selects an PopupMenu item.
	menu_list_popup.connect("id_pressed", self, "_on_menu_selected")



func _on_menu_selected( id ):
	
	match(id):
		0: 	
			ScoreManager.reset()
			get_tree().current_scene.find_node("Raster").resetBoard()
		
		1: get_tree().current_scene.find_node("Raster").fixBoard()
