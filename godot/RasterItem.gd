extends Node2D
class_name RasterItem

signal StartDragging
signal EndDragging

var isDragging = false

var rasterX = 0
var rasterY = 0

const image_list = ["04.png", "08.png", "12.png", "15.png", "16.png"]

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var image = image_list[randi() % image_list.size() - 1]
#	printt('image', image )
	var sprite = get_node("Area2D/Sprite")
	sprite.texture = load('assets/'+ image)
#	sprite.rotation_degrees = randi() % 360
	
	var spritesize = sprite.get_texture().get_size()
	
	printt("current size: ", spritesize)
	
	var th = 64 * 1.1 #target height
	var tw = 64 * 1.1#target width
	var scale = Vector2( tw / spritesize.x, th / spritesize.y)
	sprite.scale = scale
	printt("scale: ", scale)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func startSelection():
	get_node("Area2D/AnimationPlayer").play("StartDragging")
	print("should animate")
	
func endSelection():
	get_node("Area2D/AnimationPlayer").stop(true)
	get_node("Area2D/Sprite").rotation_degrees = 0
	print("stop animate")
	

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
