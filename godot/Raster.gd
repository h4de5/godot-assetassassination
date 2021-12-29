extends Node2D

const RasterItem = preload('RasterItem.tscn')


# currently dragged item
var draggingItem : RasterItem
# when true, it is not allowed to trigger another switch
var isSwitching = false
# when checking board is in progress, this is true
var isChecking = false

# combo counter for pitching sound and later for score
var comboCount = 0


# Called when the node enters the scene tree for the first time.
func _ready():
#	remove_child(get_node("RasterItem"))
	get_node("RasterItem").queue_free()
	randomize()
	
	yield(get_tree(), "idle_frame")

	for x in range(Vars.GRID_MAX_COLS):
		createNewItem(Vars.GRID_MAX_ROWS, x)
	
	yield(get_tree(), "idle_frame") 
	correctWindowSize();
	
	get_tree().get_root().connect("size_changed", self, "correctWindowSize")
	
	
func correctWindowSize():
	# set camera 
	var camera = get_node("Camera")
	camera.position = Vector2(Vars.GRID_ITEM_SIZE, Vars.GRID_ITEM_SIZE) * -1
	
	var minSize = min(OS.window_size.x, OS.window_size.y)
	
	camera.zoom = (Vector2(Vars.GRID_MAX_ROWS, Vars.GRID_MAX_COLS) * Vars.GRID_ITEM_SIZE + camera.position * -1) / Vector2(minSize, minSize) 
	
	
#	printt("zoom", camera.zoom, "position", camera.position, "window", OS.window_size, "minSize", minSize)

#	OS.window_size = Vector2(Vars.GRID_MAX_COLS, Vars.GRID_MAX_ROWS) * Vars.GRID_ITEM_SIZE + camera.position * -1
#	OS.window_size = Vector2(GRID_MAX_COLS, GRID_MAX_ROWS) * GRID_ITEM_SIZE + Vector2(GRID_ITEM_SIZE, GRID_ITEM_SIZE)
	
#	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_EXPAND, OS.window_size, 1)

func _input(event):
	if event is InputEventKey and event.is_pressed() and event.scancode == KEY_F:
		correctWindowSize()

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
#			checkCombos()
#		if freeSpace > 0:
#			var item = getGridItem(x, 0)
#			item.dropByPlaces(freeSpace)
			
# create a defined number of new items on the given x coordinate, that will drop ..
func createNewItem(rowItemCount, x):
	
	for y in range(rowItemCount):
		
		"""
			Y
			Y
		x x   x
		x x   x
		x x x x
		x x x x
		"""
			
		var ItemNode = RasterItem.instance()
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
			else:
				lastItemId = -1

	for x in range(Vars.GRID_MAX_COLS):
		var counter = 0
		var lastItemId = -1

		for y in range(Vars.GRID_MAX_ROWS):
			
			var item = getGridItem(x,y)
			if item:
				if lastItemId == item.itemId and item.itemId >= 0:
					counter = counter + 1
				else:
					counter = 1
					lastItemId = item.itemId

				if counter >= 3:
					printt("Found", lastItemId ,"group in", y, x)
					item.toBeCleaned = true
					getGridItem(x, y-1).toBeCleaned = true
					getGridItem(x, y-2).toBeCleaned = true
					checkAgain = true
			else:
				lastItemId = -1

	return checkAgain

func getGridItem(x: int, y: int) -> RasterItem:
	# Item Naming convention
	return get_node("Item "+ str(y) + "-" + str(x)) as RasterItem

# removes all items that are marked for deletion
func cleanRaster():
	var cleanAgain = true
	var hasRemoved = false
#	while cleanAgain == true:

	cleanAgain = checkCombos()
	if cleanAgain:
		comboCount += 1
		for y in range(Vars.GRID_MAX_ROWS):
			for x in range(Vars.GRID_MAX_COLS):
				var item = getGridItem(x,y)
				if item:
					if item.toBeCleaned:
						item.itemId = -2
						hasRemoved = true
						remove_child(getGridItem(x,y))
		if hasRemoved:
			SoundManager.play("res://assets/sounds/coin_02.wav", 1.0 + comboCount / 4.0, 0)
			checkFreeSpace()
	else:
		comboCount = 0
		print("no groups found")
	isChecking = false
		
	


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


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
