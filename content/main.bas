drv = driver()

'Config

mine_count = 18
sprite_size = 8
startx = 3
starty = 1
listwidth = 14
listheight = 14

'Code
rawt = 0
t = 0
mx=0
my=0
isMouse = false
hasClicked = false
gameOver = false
hasWon = false

tiles = nil
shown = nil
flags = nil

def init()
	'Tiles
	tiles = LIST()
		for i = 0 to (listwidth * listheight) - 1
		INSERT(tiles,i,0)
	next
	'Mines
	allPositions = LIST()
	for i = 0 to (listwidth * listheight) - 1
    	INSERT(allPositions, i, i)
	next

	for i = 0 to LEN(allPositions) - 1
		j = RND(0, LEN(allPositions) - 1)
    	temp = GET(allPositions, i)
    	SET(allPositions, i, GET(allPositions, j))
		SET(allPositions, j, temp)
	next
	
	for i = 0 to mine_count - 1
    	pos = GET(allPositions, i)
    	SET(tiles, pos, 1)
	next
	'Show
	shown = LIST()
	for i = 0 to (listwidth * listheight) - 1
    	INSERT(shown, i, 0)
	next
	'Flags
	flags = LIST()
	for i = 0 to (listwidth * listheight) - 1
    	INSERT(flags, i, 0)
	next
enddef

s_tile = load_resource("tile.sprite")
s_hover = load_resource("hover.sprite")
s_bomb = load_resource("bomb.sprite")
s_flag = load_resource("flag.sprite")
s_show = load_resource("shown.sprite")

init()

def uptime(delta)
	rawt = rawt + (delta)
	t = floor(rawt)
enddef

def tile(x,y,atype)
	x = (startx * sprite_size) + x * sprite_size
	y = (starty * sprite_size) + y * sprite_size
	sprite = s_tile
	if atype = 0 then
		sprite = s_tile
	elseif atype = 1 then
		sprite = s_hover
	elseif atype = 2 then
		sprite = s_bomb
	elseif atype = 3 then
		sprite = s_flag
	elseif atype = 4 then
		sprite = s_show
	endif
	SPR sprite, x, y, 0
enddef

def gtile(x, y)
    if x < 0 or y < 0 or x >= listwidth or y >= listheight then
        return -1
    endif
    return GET(tiles, y * listwidth + x)
enddef

def isShown(x, y)
	if x < 0 or y < 0 or x >= listwidth or y >= listheight then
        return nil
    endif
    return GET(shown, y * listwidth + x)
enddef

def setShown(x, y)
    SET(shown, y * listwidth + x, 1)
enddef

def isFlagged(x, y)
	if x < 0 or y < 0 or x >= listwidth or y >= listheight then
        return nil
    endif
    return GET(flags, y * listwidth + x)
enddef

def toggleFlagged(x, y)
    idx = y * listwidth + x
    if GET(flags, idx) = 1 then
        SET(flags, idx, 0)
    else
        SET(flags, idx, 1)
    endif
enddef

def neartiles(x, y)
    near = 0
    for dx = -1 to 1
        for dy = -1 to 1
            if dx <> 0 or dy <> 0 then
                nx = x + dx
                ny = y + dy
                if gtile(nx, ny) = 1 then
                    near = near + 1
                endif
            endif
        next
    next
    return near
enddef

def flood(x, y)
	if isFlagged(x, y) = 1 then return
    tilesToCheck = LIST()
    INSERT(tilesToCheck, 0, x)
    INSERT(tilesToCheck, 1, y)
    index = 0

    while index < LEN(tilesToCheck)
        tx = GET(tilesToCheck, index)
        ty = GET(tilesToCheck, index + 1)
        index = index + 2

        if tx >= 0 and ty >= 0 and tx < listwidth and ty < listheight then
            if isShown(tx, ty) = 0 and gtile(tx, ty) = 0 then
                setShown(tx, ty)
                near = neartiles(tx, ty)
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
			elseif gtile(tx, ty) = 1 then
				setShown(tx, ty)
            endif
        endif
	
	wend
enddef

def checkWin()
    shownCount = 0
    safeTiles = (listwidth * listheight) - mine_count
    for i = 0 to (listwidth * listheight) - 1
        if GET(tiles, i) = 0 and GET(shown, i) = 1 then
            shownCount = shownCount + 1
        endif
    next
    if shownCount = safeTiles then
        hasWon = true
        gameOver = false
    endif
enddef

def update(delta)	
	touch 0, tx, ty, m1,m2
	mx = ( (startx * sprite_size) - tx ) / -sprite_size
	my = ( (starty * sprite_size) - ty ) / -sprite_size
	mx = floor(mx)
	my = floor(my)
	
	if m1 or m2 then
		isMouse = true
	else
		isMouse = false
	endif
	
	for y = 0 to listheight - 1
    	for x = 0 to listwidth - 1
        	if isShown(x, y) = 0 then
            	tile(x, y, 0)
				if isFlagged(x, y) = 1 then
					tile(x, y, 3)
				endif
        	else
            	if gtile(x, y) = 1 then
					tile(x, y, 4)
                	tile(x, y, 2)
            	else
                	tile(x, y, 4)
                	n = nearTiles(x, y)
                	if n > 0 then
                    	text (startx + x) * sprite_size, (starty + y) * sprite_size, str(n), rgba(255,255,255)
                	endif
            	endif
        	endif
    	next
	next
	
	if mx > -1 and my > -1 and mx < listwidth and my < listheight then
		tile(mx, my, 1)
	endif
	
	if isMouse then
		if not hasClicked then
			hasClicked = true
			if m1 and not (hasWon or gameOver) then
				if gtile(mx, my) = 1 then
        			gameOver = true
        			for y2 = 0 to listheight - 1
            			for x2 = 0 to listwidth - 1
                			if gtile(x2, y2) = 1 then
                    			setShown(x2, y2)
                			endif
            			next
        			next
    			else
        			flood(mx, my)
        			checkWin()
    			endif
			elseif m2 and not (hasWon or gameOver) then
				if isShown(mx, my) = 0 then
        			toggleFlagged(mx, my)
    			endif
			elseif m1 and (hasWon or gameOver) then
				if my <> 14 then return
				rawt = 0
				t = 0
				hasWon = false
				gameOver = false
				init()
			endif
		endif
	else
		hasClicked = false
	endif
	
	if hasWon or gameOver then
		if my <> 14 then
			text 0,120,"RESTART?",rgba(255,255,255)
		else
			text 0,120,"RESTART!",rgba(255,0,0)
		endif
	endif
	
	if hasWon then
		text 0,0,"YOU WIN!",rgba(0,255,0)
		text 72,0,"Time: "+str(t),rgba(255,255,255)
	elseif gameOver then
		text 0,0,"YOU LOSE!",rgba(255,0,0)
		text 72,0,"Time: "+str(t),rgba(255,255,255)
	else
		uptime(delta)
		text 0,0,"Time: "+str(t),rgba(255,255,255)
	endif
enddef

update_with(drv, call(update))