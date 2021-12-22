extends Node2D

const RasterItem = preload('RasterItem.tscn')

# size of one item
const GRID_ITEM_SIZE = 70
# maxium colums in the grid
const GRID_MAX_COLS = 10
# maxium rows in the grid
const GRID_MAX_ROWS = 10

# time in seconds that a switch will take
const switchingTime = 0.75



# currently dragged item
var draggingItem : RasterItem
# when true, it is not allowed to trigger another switch
var isSwitching = false

# current grid
#var grid = [[]]

# Called when the node enters the scene tree for the first time.
func _ready():
#	remove_child(get_node("RasterItem"))
	get_node("RasterItem").queue_free()
	
	yield(get_tree(), "idle_frame")

	for y in range(GRID_MAX_COLS):
		for x in range(GRID_MAX_ROWS):
			var ItemNode = RasterItem.instance()
			ItemNode.position.x = x * GRID_ITEM_SIZE - GRID_MAX_COLS/2 * GRID_ITEM_SIZE
			ItemNode.position.y = y * GRID_ITEM_SIZE - GRID_MAX_ROWS/2 * GRID_ITEM_SIZE
			ItemNode.rasterX = x
			ItemNode.rasterY = y
			ItemNode.itemId = randi() % 5 
			# Item Naming convention
			ItemNode.name = "Item "+ str(y) + "-" + str(x)

			ItemNode.connect("StartDragging", self, "startDragging")
			ItemNode.connect("EndDragging", self, "endDragging")
			add_child(ItemNode)

# checks if there are any items that can be marked for deletion
func checkCombos():
	var checkAgain = false
	
	for y in range(GRID_MAX_COLS):
		var counter = 0
		var lastItemId = -1

		for x in range(GRID_MAX_ROWS):
			
			var item = getGridItem(x,y)
			if item:
				if lastItemId == item.itemId and item.itemId >= 0:
					counter = counter + 1
				else:
					counter = 1
					lastItemId = item.itemId

				if counter >= 3:
					printt("Found", lastItemId ,"group in ", y, x)
					item.toBeCleaned = true
					getGridItem(x-1, y).toBeCleaned = true
					getGridItem(x-2, y).toBeCleaned = true
					checkAgain = true

	for x in range(GRID_MAX_ROWS):
		var counter = 0
		var lastItemId = -1

		for y in range(GRID_MAX_COLS):
			
			var item = getGridItem(x,y)
			if item:
				if lastItemId == item.itemId and item.itemId >= 0:
					counter = counter + 1
				else:
					counter = 1
					lastItemId = item.itemId

				if counter >= 3:
					printt("Found", lastItemId ,"group in ", y, x)
					item.toBeCleaned = true
					getGridItem(x, y-1).toBeCleaned = true
					getGridItem(x, y-2).toBeCleaned = true
					checkAgain = true

	return checkAgain

func getGridItem(x: int, y: int) -> RasterItem:
	# Item Naming convention
	return get_node("Item "+ str(y) + "-" + str(x)) as RasterItem

# removes all items that are marked for deletion
func cleanRaster():
	var cleanAgain = true
	while cleanAgain == true:

		cleanAgain = checkCombos()
		if cleanAgain:
			for y in range(GRID_MAX_COLS):
				for x in range(GRID_MAX_ROWS):
					var item = getGridItem(x,y)
					if item:
#						printt("checking ", y, x, item)
						
						if item.toBeCleaned:
#							printt("removing group at ", y, x)
							item.itemId = -2
							# ToDo queue_free
							remove_child(getGridItem(x,y))
		
		else:
			print("no groups found")


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
			var oldItemId = targetItem.itemId

			targetItem.rasterX = draggingItem.rasterX
			targetItem.rasterY = draggingItem.rasterY
			draggingItem.name = "TmpItem "+ str(draggingItem.rasterY) + "-" + str(draggingItem.rasterX)
			targetItem.name = "Item "+ str(draggingItem.rasterY) + "-" + str(draggingItem.rasterX)

			draggingItem.rasterX = oldX
			draggingItem.rasterY = oldY
			draggingItem.name = "Item "+ str(oldY) + "-" + str(oldX)

#			addTween(draggingItem, targetItem.position)
#			addTween(targetItem, draggingItem.position)
			draggingItem.startTween(targetItem.position)
			targetItem.startTween(draggingItem.position)

			draggingItem.isDragging = false
			draggingItem.endSelection()
			draggingItem = null

#			printt ("elements switched ", oldGrid, " > ", grid[targetItem.rasterY][targetItem.rasterX]["itemId"] )
		else:
			printt ("elements not switched")
			draggingItem.isDragging = false
			draggingItem.endSelection()
			draggingItem = null

# add a tween to the moving item, connects to events
#func addTween(item: RasterItem, toPosition: Vector2):
#	var tween = Tween.new()
#
#	tween.name = "Tween"
#	tween.interpolate_property(item, "position",
#			item.position, toPosition, switchingTime,
#			Tween.TRANS_BOUNCE, Tween.EASE_OUT)
#
#	tween.connect("tween_step", self, "_on_Tween_step", [item])
#	tween.connect("tween_all_completed", self, "_on_Tween_all_completed", [item])
#
#	item.add_child(tween)
#
#	tween.start()


# when all movement is done, allow switching again and remove tween
func _on_Tween_all_completed(item: RasterItem):
#	printt("all movement completed")
	isSwitching = false
	item.isSwitching = false
#	item.remove_child(item.get_node("Tween"))

	cleanRaster()

# when movement is done mostly, allow switching again
func _on_Tween_step(object, key, elapsed, value, item: RasterItem):
	# allow switching of other items, after 40% of switching time
	if elapsed > switchingTime * 0.4 and isSwitching:
#		printt("movement at", key, elapsed, value)
		isSwitching = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
