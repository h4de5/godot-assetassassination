extends Node2D
class_name RasterItem

# on mouse down, draggin starts
signal StartDragging
# on mouse up, draggin ends
signal EndDragging

# when item is currently dragged
var isDragging = false
# when item is released and currently switching
# will be reset, when movement is 100% complete
var isSwitching = false

# column position in the grid
var rasterX = 0
# row position in the grid
var rasterY = 0
# type of item - currently index in image list
var itemId = -1


const image_list = ["04.png", "08.png", "12.png", "15.png", "16.png"]

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	if(itemId == -1):
		itemId = randi() % image_list.size() - 1
		
	var image = image_list[itemId]
	var sprite = get_node("Area2D/Sprite")
	sprite.texture = load('assets/'+ image)
#	sprite.rotation_degrees = randi() % 360
	var spritesize = sprite.get_texture().get_size()
		
	var th = 64 * 1.1 #target height
	var tw = 64 * 1.1 #target width
	var scale = Vector2( tw / spritesize.x, th / spritesize.y)
	sprite.scale = scale

func startSelection():
	get_node("Area2D/AnimationPlayer").play("StartDragging")
#	print("should animate")
	
func endSelection():
	get_node("Area2D/AnimationPlayer").stop(true)
	get_node("Area2D/Sprite").rotation_degrees = 0
#	print("stop animate")
	

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.is_pressed():
			emit_signal("StartDragging", self)
			printt('clicked item', event, shape_idx, name)
		else:
			emit_signal("EndDragging", self)
			printt('dropped item', event, shape_idx, name)
		

func _on_Area2D_mouse_entered():
	pass # Replace with function body.


func _on_Area2D_mouse_exited():
	pass # Replace with function body.
