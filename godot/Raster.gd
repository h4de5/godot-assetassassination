extends Node2D

const RasterItemNode = preload('RasterItem.tscn')


# currently dragged item
var draggingItem : RasterItem
# when true, it is not allowed to trigger another switch
var isSwitching = false
# when checking board is in progress, this is true
var isChecking = false

# Called when the node enters the scene tree for the first time.
func _ready():

	resetBoard()
	
	yield(get_tree(), "idle_frame") 
	correctWindowSize();
	
	get_tree().get_root().connect("size_changed", self, "correctWindowSize")
	
	ScoreManager.reset()
	
func resetBoard():
#	get_node("RasterItem").queue_free()
	
	for x in get_children():
		if x is RasterItem:
#			print(x.name)
			x.queue_free()
	yield(get_tree(), "idle_frame")
	
	randomize()
	
	for x in range(Vars.GRID_MAX_COLS):
		createNewItem(Vars.GRID_MAX_ROWS, x)
	
func fixBoard():
#	print("Fixing board")
	for x in get_children():
		if x is RasterItem:
			if x.name.begins_with("Item") == false:
				printt("Invalid item name", x.name)
				x.queue_free()
	yield(get_tree(), "idle_frame")
	
	for x in range(Vars.GRID_MAX_ROWS):
		for y in range(Vars.GRID_MAX_COLS):
			var node = getGridItem(x, y)
			if node == null:
				printt("missing node on ", x, y)
				checkFreeSpace()
			else:
				if node.rasterX != x:
					printt("invalid x raster position", node.rasterX, "should be", x)
					node.rasterX = x
				if node.rasterY != y:
					printt("invalid y raster position", node.rasterY, "should be", y)
					node.rasterY = y
				if node.position.x != x * Vars.GRID_ITEM_SIZE:
#					printt("invalid x global position", node.position.x, "should be", x * Vars.GRID_ITEM_SIZE)
					node.position.x = x * Vars.GRID_ITEM_SIZE
				if node.position.y != y * Vars.GRID_ITEM_SIZE:
#					printt("invalid y global position", node.position.y, "should be", y * Vars.GRID_ITEM_SIZE)
					node.position.y = y * Vars.GRID_ITEM_SIZE
				# TODO - check for duplicated x/y positions
		
func correctWindowSize():
	# set camera 
	var guiOffset = get_tree().current_scene.find_node("Scores")
	
	var camera: Camera2D = get_tree().current_scene.find_node("Camera")
	var gridSize = Vector2(Vars.GRID_MAX_COLS, Vars.GRID_MAX_ROWS) * Vars.GRID_ITEM_SIZE 
	
	position = gridSize / -2.0 + Vector2(1, 1) * Vars.GRID_ITEM_SIZE / 2
	var minSize = min(OS.window_size.x, OS.window_size.y - guiOffset.rect_size.y)
	
	camera.zoom = gridSize / Vector2(minSize, minSize)
	camera.offset.y = guiOffset.rect_size.y / 2 * camera.zoom.y
	
#
#func _input(event):
##	if event is InputEventKey and event.is_pressed() and event.scancode == KEY_F:
##		correctWindowSize()
#	if event is InputEventMouseButton:
#		if not event.pressed and draggingItem != null and not isSwitching:
#			printt("start", draggingItem.position, "end", event.position)

# checks if there is space below an item
func checkFreeSpace():
	
	for x in range(Vars.GRID_MAX_ROWS):
		var freeSpace = 0
		for y in range(Vars.GRID_MAX_COLS - 1, -1, -1):
			var item = getGridItem(x, y)
			if not item or item.toBeCleaned:
				freeSpace += 1
			elif freeSpace > 0:
				item.dropByPlaces(freeSpace)
				
		if freeSpace > 0:
			createNewItem(freeSpace, x)
			
# create a defined number of new items on the given x coordinate, that will drop ..
func createNewItem(rowItemCount, x):
	
	for y in range(rowItemCount):
		
		var ItemNode = RasterItemNode.instance()
#		ItemNode.position.x = x * Vars.GRID_ITEM_SIZE - Vars.GRID_MAX_COLS/2 * Vars.GRID_ITEM_SIZE
#		ItemNode.position.y = (rowItemCount * -1 + y) * Vars.GRID_ITEM_SIZE - Vars.GRID_MAX_ROWS/2 * Vars.GRID_ITEM_SIZE
		ItemNode.position.x = x * Vars.GRID_ITEM_SIZE
		ItemNode.position.y = (rowItemCount * -1 + y) * Vars.GRID_ITEM_SIZE
		
#		ItemNode.position.y = y * Vars.GRID_ITEM_SIZE - Vars.GRID_MAX_ROWS/2 * Vars.GRID_ITEM_SIZE
		var targetPosition = Vector2(0,0)
		targetPosition.x = ItemNode.position.x
#		targetPosition.y = y * Vars.GRID_ITEM_SIZE - Vars.GRID_MAX_ROWS/2 * Vars.GRID_ITEM_SIZE
		targetPosition.y = y * Vars.GRID_ITEM_SIZE
		
		ItemNode.rasterX = x
		ItemNode.rasterY = y
		
		ItemNode.itemId = randi() % Vars.ITEM_LIST_SPRITES.size()
		# Item Naming convention
		ItemNode.name = "Item "+ str(y) + "-" + str(x)
		
		ItemNode.connect("StartDragging", self, "startDragging")
		ItemNode.connect("EndDragging", self, "endDragging")
#		ItemNode.isSwitching = true
		add_child(ItemNode)
		
		yield(get_tree(), "idle_frame") 
		ItemNode.startTween(targetPosition)
	
# checks if there are any items that can be marked for deletion
func checkCombos():
	
	var checkAgain = false
	
	for y in range(Vars.GRID_MAX_ROWS):
		var counter = 0
		var lastItemId = -1

		for x in range(Vars.GRID_MAX_COLS):
			
			var item = getGridItem(x, y)
			if item:
				if lastItemId == item.itemId and item.itemId >= 0:
					counter = counter + 1
				else:
					counter = 1
					lastItemId = item.itemId

				if counter >= 3:
#					printt("Found", lastItemId ,"group in", y, x)
					item.toBeCleaned = true
					var node : RasterItem
					node = getGridItem(x-1, y)
					if node != null:
						node.toBeCleaned = true
					node = getGridItem(x-2, y)
					if node != null:
						node.toBeCleaned = true
					checkAgain = true
					ScoreManager.addComboScore(counter)
			else:
				lastItemId = -1

	for x in range(Vars.GRID_MAX_COLS):
		var counter = 0
		var lastItemId = -1

		for y in range(Vars.GRID_MAX_ROWS):
			
			var item = getGridItem(x, y)
			if item:
				if lastItemId == item.itemId and item.itemId >= 0:
					counter = counter + 1
				else:
					counter = 1
					lastItemId = item.itemId

				if counter >= 3:
#					printt("Found", lastItemId ,"group in", y, x)
					item.toBeCleaned = true
					var node : RasterItem
					node = getGridItem(x, y-1)
					if node != null:
						node.toBeCleaned = true
					node = getGridItem(x, y-2)
					if node != null:
						node.toBeCleaned = true
					checkAgain = true
					ScoreManager.addComboScore(counter)
			else:
				lastItemId = -1

	return checkAgain

func getGridItem(x: int, y: int) -> RasterItem:
	# Item Naming convention
	var nodeName = "Item "+ str(y) + "-" + str(x)
	if has_node(nodeName):
		return get_node("Item "+ str(y) + "-" + str(x)) as RasterItem
	else:
		return null

# removes all items that are marked for deletion
func cleanRaster():
	var cleanAgain = true
	var hasRemoved = false
#	while cleanAgain == true:

	cleanAgain = checkCombos()
	if cleanAgain:
		ScoreManager.increaseMultiplier()
		for y in range(Vars.GRID_MAX_ROWS):
			for x in range(Vars.GRID_MAX_COLS):
				var item = getGridItem(x, y)
				if item:
					if item.toBeCleaned:
						item.itemId = -2
						hasRemoved = true
						remove_child(getGridItem(x, y))
		if hasRemoved:
			SoundManager.play("res://assets/sounds/coin_02.wav", 1.0 + ScoreManager.multiplier_current /  4.0, 0)
			checkFreeSpace()
	else:
		ScoreManager.resetMultiplier()
		
		fixBoard()
#		print("no groups found")
	isChecking = false

# starts dragging an item
func startDragging(startItem: RasterItem):
	if draggingItem == null && not isSwitching and not startItem.isSwitching:
		draggingItem = startItem
		draggingItem.startSelection()
		draggingItem.isDragging = true

# get corrected target drag item - in case you tried to drag too far
func getCorrectTargetItem(targetItem: RasterItem) -> RasterItem:
	
	var directionX = targetItem.rasterX - draggingItem.rasterX
	var directionY = targetItem.rasterY - draggingItem.rasterY
	
	# ending on same item
	if directionX == 0 and directionY == 0: 
		return null
	
	# switch if x +- 1 OR y +-1
	if (directionX == 0 or directionY == 0) and (abs(directionX) == 1 or abs(directionY) == 1):
		return targetItem
		
	# tried to switch diagonally
	if abs(directionX) == abs(directionY):
		return null
	
	# if switching between further items
	if abs(directionX) > abs(directionY):
		if directionX > 0:
			# switch with Y,X+1
			return getGridItem(draggingItem.rasterX + 1, draggingItem.rasterY)
		else:
			# switch with Y,X-1
			return getGridItem(draggingItem.rasterX - 1, draggingItem.rasterY)
	else:
		if directionY > 0:
			# switch with Y+1,X
			return getGridItem(draggingItem.rasterX, draggingItem.rasterY + 1)
		else:
			# switch with Y-1,X
			return getGridItem(draggingItem.rasterX, draggingItem.rasterY - 1)
	
	return null

# let an item drop
func endDragging(targetItem: RasterItem):
	if draggingItem != null and targetItem != null and not isSwitching:
		targetItem = getCorrectTargetItem(targetItem)
		
		if targetItem and not targetItem.isSwitching:
			isSwitching = true
			targetItem.isSwitching = true
			draggingItem.isSwitching = true
			
			var oldX = targetItem.rasterX
			var oldY = targetItem.rasterY

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
#			printt ("elements not switched")
			draggingItem.isDragging = false
			draggingItem.endSelection()
			draggingItem = null

# when all movement is done, allow switching again and remove tween
func _on_Tween_all_completed(item: RasterItem):
	if item.isSwitching:
#		printt("all movement completed")
		isSwitching = false
		item.isSwitching = false
	#	item.remove_child(item.get_node("Tween"))
#		if not isChecking:

		if isChecking:
			return
				
		isChecking = true
#		cleanRaster()
		call_deferred("cleanRaster")

# when movement is done mostly, allow switching again
func _on_Tween_step(_object, _key, elapsed, _value, _item: RasterItem):
	# allow switching of other items, after 40% of switching time
	if elapsed > Vars.TIME_SWITCHING * 0.4 and isSwitching:
#		printt("movement at", key, elapsed, value)
		isSwitching = false
