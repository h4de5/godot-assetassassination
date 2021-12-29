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
# will be true if the item will be cleaned/removed on next refresh
var toBeCleaned = false

# column position in the grid
var rasterX = 0
# row position in the grid
var rasterY = 0
# type of item - currently index in image list
var itemId = -1


# Called when the node enters the scene tree for the first time.
func _ready():
#	randomize()
#	if(itemId == -1):
#		itemId = randi() % image_list.size() - 1
		
	var image = Vars.ITEM_LIST_SPRITES[itemId]
	var sprite = get_node("Area2D/Sprite")
	sprite.texture = load('assets/'+ image)
#	sprite.rotation_degrees = randi() % 360
	var spritesize = sprite.get_texture().get_size()
		
	var th = Vars.GRID_ITEM_SIZE #target height
	var tw = Vars.GRID_ITEM_SIZE #target width
	var scale = Vector2( tw / spritesize.x, th / spritesize.y)
	sprite.scale = scale
	
	var tween = get_node("Tween")
	tween.connect("tween_step", get_parent(), "_on_Tween_step", [self])
	tween.connect("tween_all_completed", get_parent(), "_on_Tween_all_completed", [self])

func _process(_delta):
	if Engine.get_frames_drawn() % 60 == 0:
		get_node("Area2D/TextEdit").text = str(itemId) + "\n" + str(rasterY)+"-"+str(rasterX)
		
func startSelection():
	get_node("Area2D/AnimationPlayer").play("StartDragging")
#	print("should animate")
	
func endSelection():
	get_node("Area2D/AnimationPlayer").stop(true)
	get_node("Area2D/Sprite").rotation_degrees = 0
#	print("stop animate")
	

func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.is_pressed():
			emit_signal("StartDragging", self)
#			printt('clicked item', event, shape_idx, name)
		else:
			emit_signal("EndDragging", self)
#			printt('dropped item', event, shape_idx, name)

func startTween(toPosition: Vector2):
	var tween = get_node("Tween")
	
	if tween.is_active():
		tween.stop_all()
		tween.seek(Vars.TIME_SWITCHING)
	
	tween.interpolate_property(self, "position",
			self.position, toPosition, Vars.TIME_SWITCHING,
			Tween.TRANS_BOUNCE, Tween.EASE_OUT)

	tween.start()

func dropByPlaces(itemCount: int):
	if itemCount > 0:
		rasterY += itemCount
#		var newPos = Vector2(self.position.x, rasterY * Vars.GRID_ITEM_SIZE - Vars.GRID_MAX_ROWS/2 * Vars.GRID_ITEM_SIZE)
		var newPos = Vector2(self.position.x, rasterY * Vars.GRID_ITEM_SIZE)
		
		name = "Item "+ str(rasterY) + "-" + str(rasterX)
		isSwitching = true
		startTween(newPos)
		

func _on_Area2D_mouse_entered():
	pass # Replace with function body.


func _on_Area2D_mouse_exited():
	pass # Replace with function body.
