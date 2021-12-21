extends Node2D

const RasterItem = preload('RasterItem.tscn')

# size of one item
const rasterSize = 70
# maxium colums in the grid
const rasterCols = 10
# maxium rows in the grid
const rasterRows = 10
# time in seconds that a switch will take
const switchingTime = 0.75

# currently dragged item
var draggingItem : RasterItem
# when true, it is not allowed to trigger another switch
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
			ItemNode.itemId = randi() % 5 - 1
			ItemNode.name = "Item "+ str(x) + "-" + str(y)
		
			ItemNode.connect("StartDragging", self, "startDragging")
			ItemNode.connect("EndDragging", self, "endDragging")
			add_child(ItemNode)
	
# regenerates the whole raster from scratch
func generateRaster():
	pass
	
# checks if there are any items that can be marked for deletion
func checkCombos():
	pass

# removes all items that are marked for deletion
func cleanRaster():
	pass

# starts dragging an item
func startDragging(startItem: RasterItem):
	if draggingItem == null && not isSwitching and not startItem.isSwitching:
		draggingItem = startItem
		draggingItem.startSelection()
		draggingItem.isDragging = true

# let an item drop
func endDragging(targetItem: RasterItem):
	if draggingItem != null && not isSwitching and not targetItem.isSwitching:
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
			targetItem.isSwitching = true
			draggingItem.isSwitching = true
			
			var oldX = targetItem.rasterX
			var oldY = targetItem.rasterY
			
			targetItem.rasterX = draggingItem.rasterX
			targetItem.rasterY = draggingItem.rasterY
			
			draggingItem.rasterX = oldX
			draggingItem.rasterY = oldY
			
			addTween(draggingItem, targetItem.position)
			addTween(targetItem, draggingItem.position)
			
			draggingItem.isDragging = false
			draggingItem.endSelection()
			draggingItem = null
			
			printt ("elements switched")
		else:
			printt ("elements not switched")
			draggingItem.isDragging = false
			draggingItem.endSelection()
			draggingItem = null
	
# add a tween to the moving item, connects to events
func addTween(item: RasterItem, toPosition: Vector2):
	var tween = Tween.new()
	
	tween.name = "Tween"
	tween.interpolate_property(item, "position",
			item.position, toPosition, switchingTime,
			Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	
	tween.connect("tween_step", self, "_on_Tween_step", [item])
	tween.connect("tween_all_completed", self, "_on_Tween_all_completed", [item])
	
	item.add_child(tween)

	tween.start()
	
	
# when all movement is done, allow switching again and remove tween
func _on_Tween_all_completed(item: RasterItem):
	printt("all movement completed")
	isSwitching = false
	item.isSwitching = false
	item.remove_child(item.get_node("Tween"))

# when movement is done mostly, allow switching again
func _on_Tween_step(object, key, elapsed, value, item: RasterItem):
	# allow switching of other items, after 40% of switching time
	if elapsed > switchingTime * 0.4 and isSwitching:
		printt("movement at", key, elapsed, value)
		isSwitching = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
