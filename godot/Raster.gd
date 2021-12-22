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

# current grid
var grid = [[]]

# Called when the node enters the scene tree for the first time.
func _ready():
	remove_child(get_node("RasterItem"))
	yield(get_tree(), "idle_frame")
	
	grid = generateRaster()
#	cleanRaster()
	
	for y in range(grid.size()):
		for x in range(grid[y].size()):
#	for y in grid:
#		for x in grid[y]:
			var ItemNode = RasterItem.instance()
			ItemNode.position.x = x * rasterSize - rasterCols/2 * rasterSize
			ItemNode.position.y = y * rasterSize - rasterRows/2 * rasterSize
			ItemNode.rasterX = x
			ItemNode.rasterY = y
#			ItemNode.itemId = randi() % 5 - 1
			ItemNode.itemId = grid[y][x]["itemId"]
			ItemNode.name = "Item "+ str(y) + "-" + str(x)
		
			ItemNode.connect("StartDragging", self, "startDragging")
			ItemNode.connect("EndDragging", self, "endDragging")
			add_child(ItemNode)
	
# regenerates the whole raster from scratch
func generateRaster():
	var gridNew = [[]]
	
	randomize()
	
	gridNew.resize(rasterRows)
	for y in range(rasterRows):
		gridNew[y] = []
		gridNew[y].resize(rasterCols)

		for x in range(rasterCols):
			gridNew[y][x] = {
				"itemId": (randi() % 5),
			}
	return gridNew

	
# checks if there are any items that can be marked for deletion
func checkCombos():
	var checkAgain = false
	for y in range(grid.size()):
		var counter = 0
		var lastItemId = -1
		
		for x in range(grid[y].size()):
			if lastItemId == grid[y][x]["itemId"] and grid[y][x]["itemId"] >= 0:
				counter = counter + 1
			else:
				counter = 1
				lastItemId = grid[y][x]["itemId"]
				
			if counter >= 3:
				printt("Found", lastItemId ,"group in ", y, x)
				grid[y][x]["toBeCleaned"] = true
				grid[y][x-1]["toBeCleaned"] = true
				grid[y][x-2]["toBeCleaned"] = true
				checkAgain = true
		
	for x in range(grid.size()):
		var counter = 0
		var lastItemId = -1
		
		for y in range(grid[x].size()):
			if lastItemId == grid[y][x]["itemId"] and grid[y][x]["itemId"] >= 0:
				counter = counter + 1
			else:
				counter = 1
				lastItemId = grid[y][x]["itemId"]
			
			if counter >= 3:
				printt("Found", lastItemId ,"group in ", y, x)
				grid[y][x]["toBeCleaned"] = true
				grid[y-1][x]["toBeCleaned"] = true
				grid[y-2][x]["toBeCleaned"] = true
				checkAgain = true
				
	return checkAgain
			

# removes all items that are marked for deletion
func cleanRaster():
	var cleanAgain = true
	while cleanAgain == true:
		
		cleanAgain = checkCombos()
		if cleanAgain:
			for y in range(grid.size()):
				for x in range(grid[y].size()):
					printt("checking ", y, x, grid[y][x])
					if "toBeCleaned" in grid[y][x] and grid[y][x]["toBeCleaned"]:
						printt("removing group at ", y, x)
						remove_child(get_node("Item "+ str(y) + "-" + str(x)))
						grid[y][x]["itemId"] = -2
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
			
			var oldGrid = grid[targetItem.rasterY][targetItem.rasterX]["itemId"]
			grid[targetItem.rasterY][targetItem.rasterX]["itemId"] = grid[draggingItem.rasterY][draggingItem.rasterX]["itemId"]
			grid[draggingItem.rasterY][draggingItem.rasterX]["itemId"] = oldGrid
			
			var oldX = targetItem.rasterX
			var oldY = targetItem.rasterY
			
			targetItem.rasterX = draggingItem.rasterX
			targetItem.rasterY = draggingItem.rasterY
			targetItem.name = "Item "+ str(draggingItem.rasterY) + "-" + str(draggingItem.rasterX)
			
			draggingItem.rasterX = oldX
			draggingItem.rasterY = oldY
			draggingItem.name = "Item "+ str(oldY) + "-" + str(oldX)
			
			
			addTween(draggingItem, targetItem.position)
			addTween(targetItem, draggingItem.position)
			
			draggingItem.isDragging = false
			draggingItem.endSelection()
			draggingItem = null
			
			printt ("elements switched ", oldGrid, " > ", grid[targetItem.rasterY][targetItem.rasterX]["itemId"] )
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
#	printt("all movement completed")
	isSwitching = false
	item.isSwitching = false
	item.remove_child(item.get_node("Tween"))
	
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
