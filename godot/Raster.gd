extends Node2D

const RasterItem = preload('RasterItem.tscn')

const rasterSize = 70
const rasterCols = 10
const rasterRows = 10

var draggingItem : RasterItem
var isSwitching = false

# Called when the node enters the scene tree for the first time.
func _ready():
	remove_child(get_node("RasterItem"))
	yield(get_tree(), "idle_frame")
	for y in range(rasterRows):
		for x in range(rasterCols):
			var ItemNode = RasterItem.instance()
			ItemNode.position.x = x * rasterSize - rasterCols/2 * rasterSize
			ItemNode.position.y = y * rasterSize - rasterRows/2 * rasterSize
			ItemNode.rasterX = x
			ItemNode.rasterY = y
			ItemNode.name = "Item "+ str(x) + "-" + str(y)
		
			ItemNode.connect("StartDragging", self, "startDragging")
			ItemNode.connect("EndDragging", self, "endDragging")
			add_child(ItemNode)
	

func startDragging(startItem: RasterItem):
	if draggingItem == null && not isSwitching:
		draggingItem = startItem
		draggingItem.startSelection()
		draggingItem.isDragging = true
	
func endDragging(targetItem: RasterItem):
	
	if draggingItem != null && not isSwitching:
		
		# only switch if x +- 1 OR y +-1
		if ((targetItem.rasterX + 1 == draggingItem.rasterX and
			targetItem.rasterY == draggingItem.rasterY) or
			(targetItem.rasterX - 1 == draggingItem.rasterX and
			targetItem.rasterY == draggingItem.rasterY) or
			(targetItem.rasterX == draggingItem.rasterX and
			targetItem.rasterY + 1 == draggingItem.rasterY) or
			(targetItem.rasterX == draggingItem.rasterX and
			targetItem.rasterY - 1 == draggingItem.rasterY)):
		
			isSwitching = true
			
			var oldX = targetItem.rasterX
			var oldY = targetItem.rasterY
			
			targetItem.rasterX = draggingItem.rasterX
			targetItem.rasterY = draggingItem.rasterY
			
			draggingItem.rasterX = oldX
			draggingItem.rasterY = oldY
			
			var tween1 = get_node("Tween1")
			var tween2 = get_node("Tween2")
			
			tween1.interpolate_property(draggingItem, "position",
					draggingItem.position, targetItem.position, 0.75,
					Tween.TRANS_BOUNCE, Tween.EASE_OUT)
			tween1.start()
			
			tween2.interpolate_property(targetItem, "position",
					targetItem.position, draggingItem.position, 0.75,
					Tween.TRANS_BOUNCE, Tween.EASE_OUT)
			tween2.start()
			
			
			draggingItem.isDragging = false
			draggingItem.endSelection()
			draggingItem = null
			
			printt ("elements switched")
		else:
			printt ("elements not switched")
			draggingItem.isDragging = false
			draggingItem.endSelection()
			draggingItem = null
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func _on_Tween1_tween_all_completed():
	printt("all completed")
	isSwitching = false
