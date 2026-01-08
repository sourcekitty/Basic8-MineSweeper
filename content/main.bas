'Config
minMines = 14
maxMines = 20
gridStartX = 3
gridStartY = 1
gridWidth = 14
gridHeight = 14
spriteSize = 8

'Code
drv = driver()
time = 0
selX = 0
selY = 0
mouseDown = false
mouseClicked = false
wonGame = false
lostGame = false
mines = 0
tiles = nil
shown = nil
flags = nil
nears = nil
hasStart = false

tileSprites = LIST(
	load_resource("tile.sprite"),
	load_resource("shown.sprite"),
	load_resource("bomb.sprite"),
	load_resource("flag.sprite"),
	load_resource("hover.sprite"),
	load_resource("n1.sprite"),
	load_resource("n2.sprite"),
	load_resource("n3.sprite"),
	load_resource("n4.sprite"),
	load_resource("n5.sprite"),
	load_resource("n6.sprite"),
	load_resource("n7.sprite"),
	load_resource("n8.sprite")
)

def timeTick(d)
	time = time + d
enddef

def tile(x,y,t)
	x = (gridStartX * spriteSize) + x * spriteSize
	y = (gridStartY * spriteSize) + y * spriteSize
	SPR GET(tileSprites,t), x, y, 0
enddef

def getTile(x,y)
	if x < 0 or y < 0 or x >= gridWidth or y >= gridHeight then return nil endif
    return GET(tiles, y * gridWidth + x)
enddef

def tileShown(x,y)
	if x < 0 or y < 0 or x >= gridWidth or y >= gridHeight then return nil endif
    return GET(shown, y * gridWidth + x)
enddef

def setTile(x,y,n)
	if x < 0 or y < 0 or x >= gridWidth or y >= gridHeight then return nil endif
	SET(tiles, y * gridWidth + x, n)
enddef

def tileShow(x,y)
    SET(shown, y * gridWidth + x, 1)
enddef

def tileFlagged(x,y)
	if x < 0 or y < 0 or x >= gridWidth or y >= gridHeight then return nil endif
    return GET(flags, y * gridWidth + x)
enddef

def tileFlag(x,y)
    idx = y * gridWidth + x
    if GET(flags, idx) = 1 then
        SET(flags, idx, 0)
    else
        SET(flags, idx, 1)
    endif
enddef

def tilesNear(x,y)
    near = 0
    for dx = -1 to 1
        for dy = -1 to 1
            if dx <> 0 or dy <> 0 then
                nx = x + dx
                ny = y + dy
                if getTile(nx, ny) = 1 then
                    near = near + 1
                endif
            endif
        next
    next
    return near
enddef

def flood(x,y)
	if tileFlagged(x, y) = 1 then return
    tilesToCheck = LIST()
    INSERT(tilesToCheck, 0, x)
    INSERT(tilesToCheck, 1, y)
    index = 0

    while index < LEN(tilesToCheck)
        tx = GET(tilesToCheck, index)
        ty = GET(tilesToCheck, index + 1)
        index = index + 2

        if tx >= 0 and ty >= 0 and tx < gridWidth and ty < gridHeight then
            if tileShown(tx, ty) = 0 and getTile(tx, ty) = 0 then
                tileShow(tx, ty)
                near = tilesNear(tx, ty)
                if near = 0 then
                    INSERT(tilesToCheck, LEN(tilesToCheck), tx - 1)
                    INSERT(tilesToCheck, LEN(tilesToCheck), ty)

                    INSERT(tilesToCheck, LEN(tilesToCheck), tx + 1)
                    INSERT(tilesToCheck, LEN(tilesToCheck), ty)

                    INSERT(tilesToCheck, LEN(tilesToCheck), tx)
                    INSERT(tilesToCheck, LEN(tilesToCheck), ty - 1)

                    INSERT(tilesToCheck, LEN(tilesToCheck), tx)
                    INSERT(tilesToCheck, LEN(tilesToCheck), ty + 1)
                endif
			elseif getTile(tx, ty) = 1 then
				tileShow(tx, ty)
            endif
        endif
	wend
enddef

def checkWin()
    shownCount = 0
    safeTiles = (gridWidth * gridHeight) - mines
    for i = 0 to (gridWidth * gridHeight) - 1
        if GET(tiles, i) = 0 and GET(shown, i) = 1 then
            shownCount = shownCount + 1
        endif
    next
    if shownCount = safeTiles then
        wonGame = true
        lostGame = false
		for i = 0 to (gridWidth * gridHeight) - 1
			INSERT(shown, i, 1)
		next
		for y2 = 0 to gridHeight - 1
			for x2 = 0 to gridWidth - 1
				if getTile(x2, y2) = 1 then
					if tileFlagged(x2, y2) = 1 then return
					tileFlag(x2,y2)
				endif
			next
		next
    endif
enddef

def startGame()
	'Tiles
	tiles = LIST()
	for i = 0 to (gridWidth * gridHeight) - 1
		INSERT(tiles, i, 0)
	next
	shown = CLONE(tiles)
	flags = CLONE(tiles)
	nears = LIST()
	
	'Mines
	allPositions = LIST()
	for i = 0 to (gridWidth * gridHeight) - 1
    	INSERT(allPositions, i, i)
	next

	for i = 0 to LEN(allPositions) - 1
		j = RND(0, LEN(allPositions) - 1)
    	temp = GET(allPositions, i)
    	SET(allPositions, i, GET(allPositions, j))
		SET(allPositions, j, temp)
	next
	
	for i = 0 to mines - 1
    	pos = GET(allPositions, i)
    	SET(tiles, pos, 1)
	next
	
	for y = 0 to gridHeight - 1
    	for x = 0 to gridWidth - 1
			PUSH(nears, 0)
    	next
	next
enddef

def restartGame()
	time = 0
	tiles = nil
	shown = nil
	flags = nil
	wonGame = false
	lostGame = false
	hasStarted = false
	mines = rnd(minMines,maxMines)
	startGame()
enddef

def controlTick()
	touch 0, tx, ty, m1, m2
	selX = ((gridStartX * spriteSize) - tx) / -spriteSize
	selY = ((gridStartY * spriteSize) - ty) / -spriteSize
	selX = floor(selX)
	selY = floor(selY)
	
	if m1 or m2 then
		mouseDown = true
	else
		mouseDown = false
	endif
	
	if mouseDown then
		if mouseClicked then return
		mouseClicked = true
		if m1 and not (wonGame or lostGame) then
			if hasStarted = false then
				hasStarted = true
				if getTile(selX, selY) = 1 then
					setTile(selX,selY,0)
				endif
				nears = LIST()
				for y = 0 to gridHeight - 1
    				for x = 0 to gridWidth - 1
						n = tilesNear(x, y)
						PUSH(nears, n)
    				next
				next
			elseif getTile(selX, selY) = 1 then
				if tileFlagged(selX, selY) = 1 then return
				lostGame = true
				for i = 0 to (gridWidth * gridHeight) - 1
					INSERT(flags, i, 0)
				next
				for y2 = 0 to gridHeight - 1
					for x2 = 0 to gridWidth - 1
						if getTile(x2, y2) = 1 then
							tileShow(x2 ,y2)
						endif
					next
				next
			else
				flood(selX, selY)
				checkWin()
			endif
		elseif m2 and not (wonGame or lostGame) then
			if tileShown(selX, selY) = 0 then
				tileFlag(selX,selY)
			endif
		elseif m2 and (wonGame or lostGame) then
			restartGame()
			hasStarted = false
		endif
	else
		mouseClicked = false
	endif
enddef

def renderGrid()
	for y = 0 to gridHeight - 1
    	for x = 0 to gridWidth - 1
			if tileFlagged(x, y) = 1 then
				tile(x, y, 3)
   	     	elseif tileShown(x, y) = 0 then
            	tile(x, y, 0)
        	else
            	if getTile(x, y) = 1 then
                	tile(x, y, 2)
            	else
                	n = GET(nears, y * gridWidth + x)
                	if n > 0 then
						tile(x, y, n + 4)
					else
						tile(x, y, 1)
                	endif
            	endif
        	endif
    	next
	next
enddef

mines = rnd(minMines,maxMines)
startGame()

def update(delta)
	controlTick()
	renderGrid()
	if selX > -1 and selY > -1 and selX < gridWidth and selY < gridHeight then
		tile(selX, selY, 4)
	endif
	
	if wonGame or lostGame then
		text 0,120,"Rt Click to Restart!",rgba(255,255,255)
	endif
	
	if wonGame then
		text 0,0,"YOU WIN!",rgba(0,255,0)
		text 72,0,"Time: "+str(round(time)),rgba(255,255,255)
	elseif lostGame then
		text 0,0,"YOU LOSE!",rgba(255,0,0)
	else
		timeTick(delta)
		text 0,0,"Time: "+str(round(time)),rgba(255,255,255)
	endif
enddef

update_with(drv, call(update))