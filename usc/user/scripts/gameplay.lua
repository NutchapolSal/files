-- The following code slightly simplifies the render/update code, making it easier to explain in the comments
-- It replaces a few of the functions built into USC and changes behaviour slightly
-- Ideally, this should be in the common.lua file, but the rest of the skin does not support it
-- I'll be further refactoring and documenting the default skin and making it more easy to
--  modify for those who either don't know how to skin well or just want to change a few images
--  or behaviours of the default to better suit them.
-- Skinning should be easy and fun!

local RECT_FILL = "fill"
local RECT_STROKE = "stroke"
local RECT_FILL_STROKE = RECT_FILL .. RECT_STROKE

gfx._ImageAlpha = 1
if gfx._FillColor == nil then
	gfx._FillColor = gfx.FillColor
	gfx._StrokeColor = gfx.StrokeColor
	gfx._SetImageTint = gfx.SetImageTint
end

-- we aren't even gonna overwrite it here, it's just dead to us
gfx.SetImageTint = nil

function gfx.FillColor(r, g, b, a)
    r = math.floor(r or 255)
    g = math.floor(g or 255)
    b = math.floor(b or 255)
    a = math.floor(a or 255)

    gfx._ImageAlpha = a / 255
    gfx._FillColor(r, g, b, a)
    gfx._SetImageTint(r, g, b)
end
function gfx.StrokeColor(r, g, b, a)
    r = math.floor(r or 255)
    g = math.floor(g or 255)
    b = math.floor(b or 255)
    a = math.floor(a or 255)

    gfx._ImageAlpha = a / 255
    gfx._StrokeColor(r, g, b, a)
end

-- function gfx.StrokeColor(r, g, b)
    -- r = math.floor(r or 255)
    -- g = math.floor(g or 255)
    -- b = math.floor(b or 255)
--
    -- gfx._StrokeColor(r, g, b)
-- end

function gfx.DrawRect(kind, x, y, w, h)
    local doFill = kind == RECT_FILL or kind == RECT_FILL_STROKE
    local doStroke = kind == RECT_STROKE or kind == RECT_FILL_STROKE

    local doImage = not (doFill or doStroke)

    gfx.BeginPath()

    if doImage then
        gfx.ImageRect(x, y, w, h, kind, gfx._ImageAlpha, 0)
    else
        gfx.Rect(x, y, w, h)
        if doFill then gfx.Fill() end
        if doStroke then gfx.Stroke() end
    end
end

local buttonStates = { }
local buttonsInOrder = {
    game.BUTTON_BTA,
    game.BUTTON_BTB,
    game.BUTTON_BTC,
    game.BUTTON_BTD,

    game.BUTTON_FXL,
    game.BUTTON_FXR,

    game.BUTTON_STA,
}

function UpdateButtonStatesAfterProcessed()
    for i = 1, 6 do
        local button = buttonsInOrder[i]
        buttonStates[button] = game.GetButton(button)
    end
end

function game.GetButtonPressed(button)
    return game.GetButton(button) and not buttonStates[button]
end
-- -------------------------------------------------------------------------- --
-- game.IsUserInputActive:                                                    --
-- Used to determine if (valid) controller input is happening.                --
-- Valid meaning that laser motion will not return true unless the laser is   --
--  active in gameplay as well.                                               --
-- This restriction is not applied to buttons.                                --
-- The player may press their buttons whenever and the function returns true. --
-- Lane starts at 1 and ends with 8.                                          --
function game.IsUserInputActive(lane)
    if lane < 7 then
        return game.GetButton(buttonsInOrder[lane])
    end
    return gameplay.IsLaserHeld(lane - 7)
end
-- -------------------------------------------------------------------------- --
-- gfx.FillLaserColor:                                                        --
-- Sets the current fill color to the laser color of the given index.         --
-- An optional alpha value may be given as well.                              --
-- Index may be 1 or 2.                                                       --
function gfx.FillLaserColor(index, alpha)
    alpha = math.floor(alpha or 255)
    local r, g, b = game.GetLaserColor(index - 1)
    gfx.FillColor(r, g, b, alpha)
end


-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --
--                  The actual gameplay script starts here!                   --
-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --
-- -------------------------------------------------------------------------- --
-- Global data used by many things:                                           --
local resx, resy -- The resolution of the window
local portrait -- whether the window is in portrait orientation
local desw, desh -- The resolution of the deisign
local scale -- the scale to get from design to actual units
-- -------------------------------------------------------------------------- --
-- All images used by the script:                                             --
local jacketFallback = gfx.CreateSkinImage("song_select/loading.png", 0)
local bottomFill = gfx.CreateSkinImage("console/console.png", 0)
local topFill = gfx.CreateSkinImage("fill_top.png", 0)
local critAnimImg = gfx.CreateSkinImage("crit_anim.png", gfx.IMAGE_REPEATX)
local critAnim = gfx.ImagePattern(0,-50,100,100,0,critAnimImg,1)
local critCap = gfx.CreateSkinImage("crit_cap.png", 0)
local critCapBack = gfx.CreateSkinImage("crit_cap_back.png", 0)
local laserCursor = gfx.CreateSkinImage("pointer.png", 0)
local laserCursorOverlay = gfx.CreateSkinImage("pointer_overlay.png", 0)
local earlatePos = game.GetSkinSetting("earlate_position")

local ioConsoleDetails = {
    gfx.CreateSkinImage("console/detail_left.png", 0),
    gfx.CreateSkinImage("console/detail_right.png", 0),
}

local consoleAnimImages = {
    gfx.CreateSkinImage("console/glow_bta.png", 0),
    gfx.CreateSkinImage("console/glow_btb.png", 0),
    gfx.CreateSkinImage("console/glow_btc.png", 0),
    gfx.CreateSkinImage("console/glow_btd.png", 0),

    gfx.CreateSkinImage("console/glow_fxl.png", 0),
    gfx.CreateSkinImage("console/glow_fxr.png", 0),

    gfx.CreateSkinImage("console/glow_voll.png", 0),
    gfx.CreateSkinImage("console/glow_volr.png", 0),
}
-- -------------------------------------------------------------------------- --
-- Timers, used for animations:                                               --
if introTimer == nil then
	introTimer = 2
	outroTimer = 0
end
local alertTimers = {-2,-2}

local earlateTimer = 0
local critAnimTimer = 0

local consoleAnimSpeed = 10
local consoleAnimTimers = { 0, 0, 0, 0, 0, 0, 0, 0 }
-- -------------------------------------------------------------------------- --
-- Miscelaneous, currently unsorted:                                          --
local score = 0
local combo = 0
local jacket = nil
local critLinePos = { 0.95, 0.75 };
local comboScale = 1.0
local late = false
local diffNames = {"NOV", "ADV", "EXH", "INF"}
local clearTexts = {"TRACK FAILED", "TRACK COMPLETE", "TRACK COMPLETE", "FULL COMBO", "PERFECT" }
-- -------------------------------------------------------------------------- --
-- ResetLayoutInformation:                                                    --
-- Resets the layout values used by the skin.                                 --
function ResetLayoutInformation()
    resx, resy = game.GetResolution()
    portrait = resy > resx
    desw = portrait and 720 or 1280
    desh = desw * (resy / resx)
    scale = resx / desw
end

-- not default
local seedset = false
--

-- -------------------------------------------------------------------------- --
-- render:                                                                    --
-- The primary & final render call.                                           --
-- Use this to render basically anything that isn't the crit line or the      --
--  intro/outro transitions.                                                  --
local LCDactivate = game.GetSkinSetting('LCDactivate')
local sentlcd = false
function render(deltaTime)
    -- make sure that our transform is cleared, clean working space
    -- TODO: this shouldn't be necessary!!!
    gfx.ResetTransform()
    deboxi = 0

    -- global timer
    -- for all my timey needs
    globalTimer = deltaTime + globalTimer 

    if not(seedset) then
        math.randomseed(os.time())
        seedset = math.random() + math.random() + math.random() + math.random() + math.random()
        seedset = true
    end
    gfx.Scale(scale, scale)
    local yshift = 0

    -- In portrait, we draw a banner across the top
    -- The rest of the UI needs to be drawn below that banner
    -- TODO: this isn't how it'll work in the long run, I don't think
    if portrait then yshift = draw_banner(deltaTime) end

    draw_song_info(deltaTime)
    gfx.Translate(0, yshift - 150 * math.max(introTimer - 1, 0))
    draw_score(deltaTime)
    gfx.Translate(0, -yshift + 150 * math.max(introTimer - 1, 0))
    draw_gauge(deltaTime)
	if earlatePos ~= "off" then
		draw_earlate(deltaTime)
	end
    draw_combo(deltaTime)
    draw_alerts(deltaTime)

    draw_condisp(deltaTime)
    draw_scoregraph()
    draw_liveforce()
    draw_funshits(deltaTime)
    draw_infobar()

    draw_startbox(deltaTime)
    if (not sentlcd) and LCDactivate then
        sendtolcd(deltaTime)
    end
end
-- -------------------------------------------------------------------------- --
-- SetUpCritTransform:                                                        --
-- Utility function which aligns the graphics transform to the center of the  --
--  crit line on screen, rotation include.                                    --
-- This function resets the graphics transform, it's up to the caller to      --
--  save the transform if needed.                                             --
function SetUpCritTransform()
    -- start us with a clean empty transform
    gfx.ResetTransform()
    -- translate and rotate accordingly
    gfx.Translate(gameplay.critLine.x, gameplay.critLine.y)
    gfx.Rotate(-gameplay.critLine.rotation)
end
-- -------------------------------------------------------------------------- --
-- GetCritLineCenteringOffset:                                                --
-- Utility function which returns the magnitude of an offset to center the    --
--  crit line on the screen based on its position and rotation.               --
function GetCritLineCenteringOffset()
    local distFromCenter = resx / 2 - gameplay.critLine.x
    local dvx = math.cos(gameplay.critLine.rotation)
    local dvy = math.sin(gameplay.critLine.rotation)
    return math.sqrt(dvx * dvx + dvy * dvy) * distFromCenter
end
-- -------------------------------------------------------------------------- --
-- render_crit_base:                                                          --
-- Called after rendering the highway and playable objects, but before        --
--  the built-in hit effects.                                                 --
-- This is the first render function to be called each frame.                 --
-- This call resets the graphics transform, it's up to the caller to          --
--  save the transform if needed.                                             --
function render_crit_base(deltaTime)
    -- Kind of a hack, but here (since this is the first render function
    --  that gets called per frame) we update the layout information.
    -- This means that the player can resize their window and
    --  not break everything
    ResetLayoutInformation()

    critAnimTimer = critAnimTimer + deltaTime
    SetUpCritTransform()

    -- Figure out how to offset the center of the crit line to remain
    --  centered on the players screen
    local xOffset = GetCritLineCenteringOffset()
    gfx.Translate(xOffset, 0)

    -- Draw a transparent black overlay below the crit line
    -- This darkens the play area as it passes
    gfx.FillColor(0, 0, 0, 200)
    gfx.DrawRect(RECT_FILL, -resx, 0, resx * 2, resy)

    -- The absolute width of the crit line itself
    -- we check to see if we're playing in portrait mode and
    --  change the width accordingly
    local critWidth = resx * (portrait and 1 or 0.8)

    -- get the scaled dimensions of the crit line pieces
    local clw, clh = gfx.ImageSize(critAnimImg)
    local critAnimHeight = 15 * scale
    local critAnimWidth = critAnimHeight * (clw / clh)

    local ccw, cch = gfx.ImageSize(critCap)
    local critCapHeight = critAnimHeight * (cch / clh)
    local critCapWidth = critCapHeight * (ccw / cch)

    -- draw the back half of the caps at each end
    do
        gfx.FillColor(255, 255, 255)
        -- left side
        gfx.DrawRect(critCapBack, -critWidth / 2 - critCapWidth / 2, -critCapHeight / 2, critCapWidth, critCapHeight)
        gfx.Scale(-1, 1) -- scale to flip horizontally
        -- right side
        gfx.DrawRect(critCapBack, -critWidth / 2 - critCapWidth / 2, -critCapHeight / 2, critCapWidth, critCapHeight)
        gfx.Scale(-1, 1) -- unflip horizontally
    end

    -- render the core of the crit line
    do
        -- The crit line is made up of two rects with a pattern that scrolls in opposite directions on each rect
        local numPieces = 1 + math.ceil(critWidth / (critAnimWidth * 2))
        local startOffset = critAnimWidth * ((critAnimTimer * 1.5) % 1)

        -- left side
        -- Use a scissor to limit the drawable area to only what should be visible
        gfx.UpdateImagePattern(critAnim,
            -startOffset, -critAnimHeight/2, critAnimWidth, critAnimHeight, 0, 1)
        gfx.Scissor(-critWidth / 2, -critAnimHeight / 2, critWidth / 2, critAnimHeight)
        gfx.BeginPath()
        gfx.Rect(-critWidth / 2, -critAnimHeight / 2, critWidth / 2, critAnimHeight)
        gfx.FillPaint(critAnim)
        gfx.Fill()
        gfx.ResetScissor()

        -- right side
        -- exactly the same, but in reverse
        gfx.UpdateImagePattern(critAnim,
            startOffset, -critAnimHeight/2, critAnimWidth, critAnimHeight, 0, 1)
        gfx.Scissor(0, -critAnimHeight / 2, critWidth / 2, critAnimHeight)
        gfx.BeginPath()
        gfx.Rect(0, -critAnimHeight / 2, critWidth / 2, critAnimHeight)
        gfx.FillPaint(critAnim)
        gfx.Fill()
        gfx.ResetScissor()
    end

    -- Draw the front half of the caps at each end
    do
        gfx.FillColor(255, 255, 255)
        -- left side
        gfx.DrawRect(critCap, -critWidth / 2 - critCapWidth / 2, -critCapHeight / 2, critCapWidth, critCapHeight)
        gfx.Scale(-1, 1) -- scale to flip horizontally
        -- right side
        gfx.DrawRect(critCap, -critWidth / 2 - critCapWidth / 2, -critCapHeight / 2, critCapWidth, critCapHeight)
        gfx.Scale(-1, 1) -- unflip horizontally
    end

    -- we're done, reset graphics stuffs
    gfx.FillColor(255, 255, 255)
    gfx.ResetTransform()
end
-- -------------------------------------------------------------------------- --
-- render_crit_overlay:                                                       --
-- Called after rendering built-int crit line effects.                        --
-- Use this to render laser cursors or an IO Console in portrait mode!        --
-- This call resets the graphics transform, it's up to the caller to          --
--  save the transform if needed.                                             --
function render_crit_overlay(deltaTime)
    SetUpCritTransform()

    -- Figure out how to offset the center of the crit line to remain
    --  centered on the players screen.
    local xOffset = GetCritLineCenteringOffset()

    -- When in portrait, we can draw the console at the bottom
    if portrait then
        -- We're going to make temporary modifications to the transform
        gfx.Save()
        gfx.Translate(xOffset * 0.5, 0)

        local bfw, bfh = gfx.ImageSize(bottomFill)

        local distBetweenKnobs = 0.446
        local distCritVertical = 0.098

        local ioFillTx = bfw / 2
        local ioFillTy = bfh * distCritVertical -- 0.098

        -- The total dimensions for the console image
        local io_x, io_y, io_w, io_h = -ioFillTx, -ioFillTy, bfw, bfh

        -- Adjust the transform accordingly first
        local consoleFillScale = (resx * 0.775) / (bfw * distBetweenKnobs)
        gfx.Scale(consoleFillScale, consoleFillScale);

        -- Actually draw the fill
        gfx.FillColor(255, 255, 255)
        gfx.DrawRect(bottomFill, io_x, io_y, io_w, io_h)

        -- Then draw the details which need to be colored to match the lasers
        for i = 1, 2 do
            gfx.FillLaserColor(i)
            gfx.DrawRect(ioConsoleDetails[i], io_x, io_y, io_w, io_h)
        end

        -- Draw the button press animations by overlaying transparent images
        gfx.GlobalCompositeOperation(gfx.BLEND_OP_LIGHTER)
        for i = 1, 6 do
            -- While a button is held, increment a timer
            -- If not held, that timer is set back to 0
            if game.GetButton(buttonsInOrder[i]) then
                consoleAnimTimers[i] = consoleAnimTimers[i] + deltaTime * consoleAnimSpeed * 3.14 * 2
            else
                consoleAnimTimers[i] = 0
            end

            -- If the timer is active, flash based on a sin wave
            local globalTimer  = consoleAnimTimers[i]
            if globalTimer  ~= 0 then
                local image = consoleAnimImages[i]
                local alpha = (math.sin(timer) * 0.5 + 0.5) * 0.5 + 0.25
                gfx.FillColor(255, 255, 255, alpha * 255);
                gfx.DrawRect(image, io_x, io_y, io_w, io_h)
            end
        end
        gfx.GlobalCompositeOperation(gfx.BLEND_OP_SOURCE_OVER)

        -- Undo those modifications
        gfx.Restore();
    end

    local cw, ch = gfx.ImageSize(laserCursor)
    local cursorWidth = 40 * scale
    local cursorHeight = cursorWidth * (ch / cw)

    -- draw each laser cursor
    for i = 1, 2 do
        local cursor = gameplay.critLine.cursors[i - 1]
        local pos, skew = cursor.pos, cursor.skew

        -- Add a kinda-perspective effect with a horizontal skew
        gfx.SkewX(skew)

        -- Draw the colored background with the appropriate laser color
        gfx.FillLaserColor(i, cursor.alpha * 255)
        gfx.DrawRect(laserCursor, pos - cursorWidth / 2, -cursorHeight / 2, cursorWidth, cursorHeight)
        -- Draw the uncolored overlay on top of the color
        gfx.FillColor(255, 255, 255, cursor.alpha * 255)
        gfx.DrawRect(laserCursorOverlay, pos - cursorWidth / 2, -cursorHeight / 2, cursorWidth, cursorHeight)
        -- Un-skew
        gfx.SkewX(-skew)
    end

    -- We're done, reset graphics stuffs
    gfx.FillColor(255, 255, 255)
    gfx.ResetTransform()
end
-- -------------------------------------------------------------------------- --
-- draw_banner:                                                               --
-- Renders the banner across the top of the screen in portrait.               --
-- This function expects no graphics transform except the design scale.       --
function draw_banner(deltaTime)
    local bannerWidth, bannerHeight = gfx.ImageSize(topFill)
    local actualHeight = desw * (bannerHeight / bannerWidth)

    gfx.FillColor(255, 255, 255)
    gfx.DrawRect(topFill, 0, 0, desw, actualHeight)

    return actualHeight
end
-- -------------------------------------------------------------------------- --
-- draw_stat:                                                                 --
-- Draws a formatted name + value combination at x, y over w, h area.         --
function draw_stat(x, y, w, h, name, value, format, r, g, b)
    gfx.Save()

    -- Translate from the parent transform, wherever that may be
    gfx.Translate(x, y)

    -- Draw the `name` top-left aligned at `h` size
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP)
    gfx.FontSize(h)
    gfx.Text(name .. ":", 0, 0) -- 0, 0, is x, y after translation

    -- Realign the text and draw the value, formatted
    gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_TOP)
    gfx.Text(string.format(format, value), w, 0)
    -- This draws an underline beneath the text
    -- The line goes from 0, h to w, h
    gfx.BeginPath()
    gfx.MoveTo(0, h)
    gfx.LineTo(w, h) -- only defines the line, does NOT draw it yet

    -- If a color is provided, set it
    if r then gfx.StrokeColor(r, g, b)
    -- otherwise, default to a light grey
    else gfx.StrokeColor(200, 200, 200) end

    -- Stroke out the line
    gfx.StrokeWidth(1)
    gfx.Stroke()
    -- Undo our transform changes
    gfx.Restore()

    -- Return the next `y` position, for easier vertical stacking
    return y + h + 5
end
-- -------------------------------------------------------------------------- --
-- draw_song_info:                                                            --
-- Draws current song information at the top left of the screen.              --
-- This function expects no graphics transform except the design scale.       --
function draw_song_info(deltaTime)
    local songInfoWidth = 400
    local jacketWidth = 100
    -- Check to see if there's a jacket to draw, and attempt to load one if not
    if jacket == nil or jacket == jacketFallback then
        jacket = gfx.LoadImageJob(gameplay.jacketPath, jacketFallback)
    end

    gfx.Save()

    -- Add a small margin at the edge
    gfx.Translate(5,5)
    -- There's less screen space in portrait, the playable area is effectively a square
    -- We scale down to take up less space
    if portrait then gfx.Scale(0.7, 0.7) end

    -- Ensure the font has been loaded
    gfx.LoadSkinFont("NotoSans-Regular.ttf")

    --start of my shit--
    -- Draw the background, a "feature" of the game
    gfx.BeginPath()
    gfx.Rect(0, 0, songInfoWidth, 100)
    gfx.FillColor(20, 20, 20, 200)
    gfx.Fill()
    -- Draw the jacket
    gfx.FillColor(255, 255, 255)
    gfx.ImageRect(0, 0, jacketWidth, jacketWidth, jacket, 1, 0)

    gfx.FillColor(0, 0, 0, 192)
    gfx.DrawRect(RECT_FILL, jacketWidth, 0, songInfoWidth - jacketWidth, 100)
    --end of my shit--
    -- Draw a background for the following level stat
    gfx.FillColor(0, 0, 0, 200)
    gfx.DrawRect(RECT_FILL, 0, 85, 60, 15)
    -- Level Name : Level Number
    gfx.FillColor(255, 255, 255)
    draw_stat(0, 85, 55, 15, diffNames[gameplay.difficulty + 1], gameplay.level, "%02d")
    -- Reset some text related stuff that was changed in draw_state
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT)
    gfx.FontSize(30)

    gfx.FillColor(255, 255, 255)

    local textX = jacketWidth + 10
    local titleWidth = songInfoWidth - jacketWidth - 20
    local x1, y1, x2, y2 = gfx.TextBounds(0, 0, gameplay.title)
    local textscale = math.min(titleWidth / x2, 1)

    gfx.Save()
    do  -- Draw the song title, scaled to fit as best as possible
        gfx.Translate(textX, 30)
        gfx.Scale(textscale, textscale)
        gfx.Text(gameplay.title, 0, 0)
    end
    gfx.Restore()

    x1,y1,x2,y2 = gfx.TextBounds(0,0,gameplay.artist)
    textscale = math.min(titleWidth / x2, 1)

    gfx.Save()
    do  -- Draw the song artist, scaled to fit as best as possible
        gfx.Translate(textX, 60)
        gfx.Scale(textscale, textscale)
        gfx.Text(gameplay.artist, 0, 0)
    end
    gfx.Restore()

    -- Draw the BPM
    gfx.FontSize(20)
    gfx.Text(string.format("BPM: %.1f", gameplay.bpm), textX, 85)

    -- Fill the progress bar
    gfx.FillColor(0, 150, 255)
    gfx.DrawRect(RECT_FILL, jacketWidth, jacketWidth - 10, (songInfoWidth - jacketWidth) * gameplay.progress, 10)

    -- When the player is holding Start, the hispeed can be changed
    -- Shows the current hispeed values
    if game.GetButton(game.BUTTON_STA) then
        gfx.FillColor(20, 20, 20, 200);
        gfx.DrawRect(RECT_FILL, 100, 100, songInfoWidth - 100, 20)
        gfx.FillColor(255, 255, 255)
        if game.GetButton(game.BUTTON_BTB) then
            gfx.Text(string.format("Hid/Sud Cutoff: %.1f%% / %.1f%%",
                    gameplay.hiddenCutoff * 100, gameplay.suddenCutoff * 100),
                    textX, 115)

        elseif game.GetButton(game.BUTTON_BTC) then
            gfx.Text(string.format("Hid/Sud Fade: %.1f%% / %.1f%%",
                    gameplay.hiddenFade * 100, gameplay.suddenFade * 100),
                    textX, 115)
        else
            gfx.Text(string.format("HiSpeed: %.0f x %.1f = %.0f",
                    gameplay.bpm, gameplay.hispeed, gameplay.bpm * gameplay.hispeed),
                    textX, 115)
        end
    end

    -- aaaand, scene!
    gfx.Restore()
end
-- -------------------------------------------------------------------------- --
-- draw_best_diff:                                                            --
-- If there are other saved scores, this displays the difference between      --
--  the current play and your best.                                           --
function draw_best_diff(deltaTime, x, y)
    -- Don't do anything if there's nothing to do
    if not gameplay.scoreReplays[1] then return end

    -- Calculate the difference between current and best play
    local difference = score - gameplay.scoreReplays[1].currentScore
    local prefix = "" -- used to properly display negative values

    gfx.BeginPath()
    gfx.FontSize(40)

    gfx.FillColor(255, 255, 255)
    if difference < 0 then
        -- If we're behind the best score, separate the minus sign and change the color
        gfx.FillColor(255, 50, 50)
        difference = math.abs(difference)
        prefix = "-"
    elseif difference > 0 then --ayy mine
        gfx.FillColor(50, 255, 50)
        prefix = "+"
    end

    -- %08d formats a number to 8 characters
    -- This includes the minus sign, so we do that separately
    gfx.Text(string.format("%s%08d", prefix, difference), x, y)
end
-- -------------------------------------------------------------------------- --
-- draw_score:                                                                --
function draw_score(deltaTime)
    gfx.BeginPath()
    gfx.LoadSkinFont("NovaMono.ttf")
    gfx.BeginPath()
    gfx.RoundedRectVarying(desw - 210, 5, 220, 62, 0, 0, 0, 20)
    gfx.FillColor(20, 20, 20)
    gfx.StrokeColor(0, 128, 255)
    gfx.StrokeWidth(2)
    gfx.Fill()
    gfx.Stroke()
    gfx.Translate(-5, 5) -- upper right margin
    gfx.FillColor(255, 255, 255)
    gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_TOP)
    gfx.FontSize(60)
    gfx.Text(string.format("%08d", score), desw, 0)
    draw_best_diff(deltaTime, desw, 66)
    gfx.Translate(5, -5) -- undo margin
end
-- -------------------------------------------------------------------------- --
local gaugeTime = 0
local gg = {}
local extGaugetype = -1
-- draw_gauge:                                                                --
function draw_gauge(deltaTime)
    local height = 1024 * scale * 0.35
    local width = 512 * scale * 0.35
    local posy = resy / 2 - height / 2
    local posx = resx - width * (1 - math.max(introTimer - 1, 0))
    if portrait then
        width = width * 0.8
        height = height * 0.8
        posy = posy - 30
        posx = resx - width * (1 - math.max(introTimer - 1, 0))
    end
    gfx.DrawGauge(gameplay.gauge, posx, posy, width, height, deltaTime)

	--draw gauge % label
	posx = posx / scale
	posx = posx + (100 * 0.35)
	height = 880 * 0.35
	posy = posy / scale
	if portrait then
		height = height * 0.8;
	end

	posy = posy + (70 * 0.35) + height - height * gameplay.gauge
	gfx.BeginPath()
	gfx.Rect(posx-35, posy-10, 40, 20)
	gfx.FillColor(0,0,0,200)
	gfx.Fill()
	gfx.FillColor(255,255,255)
	gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_MIDDLE)
	gfx.FontSize(20)
	gfx.Text(string.format("%d%%", math.floor(gameplay.gauge * 100)), posx, posy )

    --gaugegraph

    --add one every <time> and when its not outro or intro
    if gaugeTime > 0.0625 and outroTimer == 0 and introTimer == 0 then
        table.insert(gg, 1, posy)
        gaugeTime = 0
    else
        gaugeTime = gaugeTime + deltaTime
    end

    if #gg > 10000 then
        table.remove(gg, #gg)
    end

    --the line
    gfx.BeginPath()
    gfx.MoveTo(posx, posy)
    for i, v in pairs(gg) do
        gfx.LineTo(posx - (0.0625 * (i - 1)), v)
    end
    gfx.StrokeWidth(1.0)

    height = 1024 * scale * 0.35
    posy = resy / 2 - height / 2
    if portrait then
        posy = posy - 30
    end
    height = 880 * 0.35
    posy = posy / scale
    if portrait then
        height = height * 0.8;
    end
    local svntycut = posy + (70 * 0.35) + height - height * 0.7
    local thirtycut = posy + (70 * 0.35) + height - height * 0.3

    if extGaugetype == -1  then
        if gameplay.gauge > 0.5 then
            extGaugetype = 1
        else
            extGaugetype = 0
        end
    end

    if extGaugetype == 1 then -- ex gauge
        gfx.StrokeColor(127,40,0)
        gfx.Stroke()
        gfx.StrokeColor(255,80,0)
        gfx.Scissor(0, 0, 1280, thirtycut)
        gfx.Stroke()
    else -- normal gauge
        gfx.StrokeColor(0,180,255)
        gfx.Stroke()
        gfx.StrokeColor(255,0,255)
        gfx.Scissor(0, 0, 1280, svntycut)
        gfx.Stroke()
    end
    gfx.ResetScissor()
    gfx.StrokeWidth(2.0)
end
-- -------------------------------------------------------------------------- --
-- draw_combo:                                                                --
function draw_combo(deltaTime)
    if combo == 0 then return end
    local posx = desw / 2
    local posy = desh * critLinePos[1] - 100
    if portrait then posy = desh * critLinePos[2] - 150 end
    gfx.BeginPath()
    gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_MIDDLE)
    if gameplay.comboState == 2 then
        gfx.FillColor(100,255,0) --puc
    elseif gameplay.comboState == 1 then
        gfx.FillColor(255,200,0) --uc
    else
        gfx.FillColor(255,255,255) --regular
    end
    gfx.LoadSkinFont("NovaMono.ttf")
    gfx.FontSize(70 * math.max(comboScale, 1))
    comboScale = comboScale - deltaTime * 3
    gfx.Text(tostring(combo), posx, posy)
end
-- -------------------------------------------------------------------------- --
-- draw_earlate:                                                              --
function draw_earlate(deltaTime)
    earlateTimer = math.max(earlateTimer - deltaTime,0)
    if earlateTimer == 0 then return nil end
    local alpha = math.floor(earlateTimer * 20) % 2
    alpha = alpha * 200 + 55
    gfx.BeginPath()
    gfx.FontSize(20)
    gfx.TextAlign(gfx.TEXT_ALIGN_CENTER, gfx.TEXT_ALIGN_MIDDLE)
    local ypos = desh * critLinePos[1] - 150
    if portrait then ypos = desh * critLinePos[2] - 200 end
	if earlatePos == "middle" then
		ypos = ypos - 200
	elseif earlatePos == "top" then
		ypos = ypos - 400
	end

    if late then
        gfx.FillColor(0,255,255, alpha)
        gfx.Text("> LATE <", desw / 2, ypos)
    else
        gfx.FillColor(255,0,255, alpha)
        gfx.Text("> EARLY <", desw / 2, ypos)
    end
end
--------------------------------------------------------------------------------
function gfx.DrawRectBool(fill, stroke, x, y, w, h)
    local doFill = fill
    local doStroke = stroke
    gfx.BeginPath()
    gfx.Rect(x, y, w, h)
    if doFill then gfx.Fill() end
    if doStroke then gfx.Stroke() end
end
--------------------------------------------------------------------------------
function gfx.DrawCircleBool(fill, stroke, x, y, r)
    local doFill = fill
    local doStroke = stroke
    gfx.BeginPath()
    gfx.Circle(x, y, r)
    if doFill then gfx.Fill() end
    if doStroke then gfx.Stroke() end
end
--------------------------------------------------------------------------------
function gfx.DrawLine(x,y,dx,dy,w)
    gfx.BeginPath()
    gfx.MoveTo(x, y)
    gfx.LineTo(x + dx, y + dy)
    gfx.StrokeWidth(w)
    gfx.Stroke()

end
--------------------------------------------------------------------------------
local lspeed, rspeed, lfirst, rfirst, llast, rlast, lsc, rsc, lmax, rmax, lmaxlist, rmaxlist = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, {}, {}
local ls, rs, templs, temprs = {}, {}, {}, {}
local cdtimer = 0
local debuglist = {}
--------------------------------------------------------------------------------
function draw_condisp(deltaTime)
    --Nutchapol's CONtroller DISPlay v3
    --https://github.com/NutchapolSal/files/tree/master/usc/condisp
    --total wxh= 227x108
    --margins: 13px
    --with margins=253x134
    --top left anchor, does not include margin
    gfx.Save()

    local condispscale = 0.5
    local posx = (13 * condispscale) --13 = attached to left, desw - 183 or 1097 = attached to right
    local posy = desh - (121 * condispscale) --13 = attached to top, desh - 121 or 599 = attached to bottom

    lfirst = game.GetKnob(0)--get some
    rfirst = game.GetKnob(1)--knob measurements

    gfx.Translate(((posx + 253) * (1 - math.max(introTimer - 1, 0))) - 253, posy)
    gfx.Scale(condispscale, condispscale)

    gfx.FillColor(0, 0, 0, 128) --transparent bg
    gfx.DrawRectBool(true, false, -13, -13, 253, 134)

    gfx.Save()
    gfx.Translate(114, 9)
    gfx.Rotate(math.rad(45))
    gfx.StrokeColor(0, 0, 128) --start
    gfx.FillColor(0, 0, 255)
    gfx.DrawRectBool(game.GetButton(6), true, -9, -9, 19, 19)
    gfx.Restore()

    gfx.StrokeColor(255, 255, 255) --bt
    gfx.FillColor(0, 128, 255)
    gfx.DrawRectBool(game.GetButton(0), true, 28, 36, 36, 36)
    gfx.DrawRectBool(game.GetButton(1), true, 73, 36, 36, 36)
    gfx.DrawRectBool(game.GetButton(2), true, 118, 36, 36, 36)
    gfx.DrawRectBool(game.GetButton(3), true, 163, 36, 36, 36)

    gfx.StrokeColor(50, 50, 50) --fx
    gfx.FillColor(255, 0, 0)
    gfx.DrawRectBool(game.GetButton(4), true, 54, 89, 29, 19)
    gfx.DrawRectBool(game.GetButton(5), true, 144, 89, 29, 19)

    --here starts the knobs
    lsc = lfirst - llast--calculate knob speeds
    rsc = rfirst - rlast

    if not(lsc > -1 and lsc < 1) then lsc = 0 end--cutoff when the getknob value jumps back to 0 (common)
    if not(rsc > -1 and rsc < 1) then rsc = 0 end

    lspeed = 0 --reset knobspeed
    rspeed = 0
    if cdtimer > 0.008 then --every 0.008 seconds
        table.insert(templs, 1, lsc) -- put readings
        table.insert(temprs, 1, rsc)

        for i, v in pairs(templs) do --sum the speeds obtained from all readings between last time and this time
            lspeed = lspeed + v
        end
        for i, v in pairs(temprs) do
            rspeed = rspeed + v
        end

        lspeed = lspeed / #templs --average them out
        rspeed = rspeed / #temprs

        table.insert(ls, 1, lspeed) --put it in the fps-normalized(? lmao idk) table
        table.insert(rs, 1, rspeed)

        templs = {}
        temprs = {}

        cdtimer = cdtimer - 0.008 + deltaTime
    else
        table.insert(templs, 1, lsc) -- put readings into wait
        table.insert(temprs, 1, rsc)
        cdtimer = cdtimer + deltaTime
    end

    lspeed = 0
    rspeed = 0

    for i, v in pairs(ls) do --sum the table
        lspeed = lspeed + v
    end
    for i, v in pairs(rs) do
        rspeed = rspeed + v
    end

    lspeed = lspeed / #ls --average them out
    rspeed = rspeed / #rs

    if #ls == 0 then lspeed = 0 end
    if #rs == 0 then rspeed = 0 end

    if #ls > 10 then table.remove(ls, #ls) end --remove off limit entries
    if #rs > 10 then table.remove(rs, #rs) end

    if #lmaxlist < 20 then --update the maximums
        table.insert(lmaxlist, 1, math.max(math.abs(lspeed),1e-20))
    elseif math.abs(lspeed) > lmaxlist[1] then
        table.insert(lmaxlist, 1, math.abs(lspeed))
        table.remove(lmaxlist, #lmaxlist)
    end

    if #rmaxlist < 20 then
        table.insert(rmaxlist, 1, math.max(math.abs(rspeed),1e-20))
    elseif math.abs(rspeed) > rmaxlist[1] then
        table.insert(rmaxlist, 1, math.abs(rspeed))
        table.remove(rmaxlist, #rmaxlist)
    end

    lmax = 0
    rmax = 0
    for i, v in pairs(lmaxlist) do
        lmax = lmax + v
    end
    for i, v in pairs(rmaxlist) do
        rmax = rmax + v
    end
    lmax = lmax / #lmaxlist
    rmax = rmax / #rmaxlist

    gfx.StrokeColor(game.GetLaserColor(0))
    gfx.FillLaserColor(1, math.floor(math.min(math.abs(lspeed) / lmax * 255,255)))--set fill color to knob color w/ transparency. opaque = u spin knob, can't see knob fill = u no spin knob
    gfx.DrawLine(9.5, 3.5, lspeed * (24 / lmax), 0, 2) --the bar
    gfx.DrawCircleBool(true, true, 8.5, 13.5, 9) --the knob circle

    gfx.StrokeColor(game.GetLaserColor(1))
    gfx.FillLaserColor(2, math.floor(math.min(math.abs(rspeed) / rmax * 255,255)))
    gfx.DrawLine(218.5, 3.5, rspeed * (24 / rmax), 0, 2)
    gfx.DrawCircleBool(true, true, 217.5, 13.5, 9)

    llast = game.GetKnob(0)--get some
    rlast = game.GetKnob(1)--knob measurements for next time
    gfx.Restore()
end
--------------------------------------------------------------------------------
function draw_scoregraph()
    local length = 200 --all bar width
    local count = #gameplay.scoreReplays --too lazy to type this thing
    local height = 5 --past yous' bar height
    local gutter = 1 --space between each bar
    gfx.Save()

    gfx.Translate(5, 130)

    gfx.FillColor(63, 63, 63) --background
    gfx.DrawRectBool(true, false, 0, 0 , length, 5)

    if count == 0 then --your score
        gfx.FillColor(255, 255, 255) --first score on map
    elseif gameplay.scoreReplays[1].currentScore < score then
        gfx.FillColor(127, 255, 127) --above best scorereplay
    elseif gameplay.scoreReplays[1].currentScore > score then
        gfx.FillColor(255, 127, 127) --below
    else
        gfx.FillColor(255, 255, 255) --equal
    end
    gfx.DrawRectBool(true, false, 0, 0 , (score / 10000000) * length, 5)

    gfx.Translate(0, 5) --here comes past yous
    if count > 5 then --past yous bars' gets smaller the more past yous you have
        height = 3 --small mode
    elseif count > 10 then
        height = 2 --compact mode
    end
    if count > 10 then --no gutter if more past yous
        gutter = 0
    end
    if not(count == 0) then --no looking at nil values
        local j = 1 --y pos in case a score gets killed(look below) so it wont leave holes in the graph
        for i = 1, count, 1 do --for each past yous

            if i == 1 then --no looking at nil values, and also i dont need you to die so
            elseif gameplay.scoreReplays[i].maxScore == 10000000 then --only 1 perfect can exist in this score graph
                j = j - 1
                goto die
            end

            gfx.FillColor(63, 63, 63) --background
            gfx.DrawRectBool(true, false, 0, (height + gutter) * j, length, height)

            if gameplay.scoreReplays[i].maxScore == 10000000 then --final score colors
                gfx.FillColor(127, 127, 0) --gold for perfects
            elseif i == 1 then --no looking at nil values
                gfx.FillColor(127, 127, 127) --you get gray
            elseif gameplay.scoreReplays[i].maxScore == gameplay.scoreReplays[i - 1].maxScore then
                gfx.FillColor(0, 0, 127) --blue for this one equal to above
            else
                gfx.FillColor(127, 127, 127) --gray for others
            end
            gfx.DrawRectBool(true, false, 0, (height + gutter) * j, (gameplay.scoreReplays[i].maxScore / 10000000) * length, height)

            if gameplay.scoreReplays[i].maxScore == 10000000 then
                gfx.FillColor(255, 255, 191) --always bright yellow for perfects
            elseif i == count then --no looking at nil values
                gfx.FillColor(191, 191, 191) --bright gray for last score
            elseif gameplay.scoreReplays[i + 1].currentScore > gameplay.scoreReplays[i].currentScore then
                gfx.FillColor(255, 191, 191) --pink for this one worse than under
            elseif i == 1 then --no looking at nil values
                gfx.FillColor(191, 191, 191) --bright gray for first score
            elseif gameplay.scoreReplays[i - 1].currentScore == gameplay.scoreReplays[i].currentScore then
                gfx.FillColor(191, 191, 255) --bright blue for this one equal above
            else
                gfx.FillColor(191, 191, 191) --bright gray otherwise
            end
            gfx.DrawRectBool(true, false, 0, (height + gutter) * j , (gameplay.scoreReplays[i].currentScore / 10000000) * length, height)
            ::die::
            j = j + 1
        end
    end
    gfx.Restore()
end
--------------------------------------------------------------------------------
local grades = {
    {["num"] = 1, ["min"] = 9900000, ["rate"] = 1.05}, -- S
    {["num"] = 2, ["min"] = 9800000, ["rate"] = 1.02}, -- AAA+
    {["num"] = 3, ["min"] = 9700000, ["rate"] = 1},    -- AAA
    {["num"] = 4, ["min"] = 9500000, ["rate"] = 0.97}, -- AA+
    {["num"] = 5, ["min"] = 9300000, ["rate"] = 0.94}, -- AA
    {["num"] = 6, ["min"] = 9000000, ["rate"] = 0.91}, -- A+
    {["num"] = 7, ["min"] = 8700000, ["rate"] = 0.88}, -- A
    {["num"] = 8, ["min"] = 7500000, ["rate"] = 0.85}, -- B
    {["num"] = 9, ["min"] = 6500000, ["rate"] = 0.82}, -- C
    {["num"] = 10, ["min"] =       0, ["rate"] = 0.8}   -- D
}

local gradesimg = {
    gfx.CreateSkinImage("score/S.png", 0),
    gfx.CreateSkinImage("score/AAA+.png", 0),
    gfx.CreateSkinImage("score/AAA.png", 0),
    gfx.CreateSkinImage("score/AA+.png", 0),
    gfx.CreateSkinImage("score/AA.png", 0),
    gfx.CreateSkinImage("score/A+.png", 0),
    gfx.CreateSkinImage("score/A.png", 0),
    gfx.CreateSkinImage("score/B.png", 0),
    gfx.CreateSkinImage("score/C.png", 0),
    gfx.CreateSkinImage("score/D.png", 0),
}

local badges = {
    1.1,  -- PUC
    1.04, -- UC
    1.02, -- Hard clear
    1.0,  -- Cleared
    0.5   -- Played
}

local badgesimg = {
    gfx.CreateSkinImage("badges/perfect.png", 0),
    gfx.CreateSkinImage("badges/full-combo.png", 0),
    gfx.CreateSkinImage("badges/hard-clear.png", 0),
    gfx.CreateSkinImage("badges/clear.png", 0),
    gfx.CreateSkinImage("badges/played.png", 0),
}

local classes = {
    {["name"] = "Imperial", ["r"] = 161, ["g"] = 63, ["b"] = 229, ["i"] =0.4, ["ii"] =0.42, ["iii"] =0.44, ["iv"] =0.46},
    {["name"] = "Crimson", ["r"] = 151, ["g"] = 1, ["b"] = 1, ["i"] =0.38, ["ii"] =0.385, ["iii"] =0.39, ["iv"] =0.395},
    {["name"] = "Eldora", ["r"] = 248, ["g"] = 222, ["b"] = 82, ["i"] =0.36, ["ii"] =0.365, ["iii"] =0.37, ["iv"] =0.375},
    {["name"] = "Argento", ["r"] = 203, ["g"] = 203, ["b"] = 206, ["i"] =0.34, ["ii"] =0.345, ["iii"] =0.35, ["iv"] =0.355},
    {["name"] = "Coral", ["r"] = 253, ["g"] = 126, ["b"] = 163, ["i"] =0.32, ["ii"] =0.325, ["iii"] =0.33, ["iv"] =0.335},
    {["name"] = "Scarlet", ["r"] = 237, ["g"] = 2, ["b"] = 2, ["i"] =0.3, ["ii"] =0.305, ["iii"] =0.31, ["iv"] =0.315},
    {["name"] = "Cyan", ["r"] = 32, ["g"] = 239, ["b"] = 213, ["i"] =0.28, ["ii"] =0.285, ["iii"] =0.29, ["iv"] =0.295},
    {["name"] = "Dandelion", ["r"] = 255, ["g"] = 171, ["b"] = 0, ["i"] =0.24, ["ii"] =0.25, ["iii"] =0.26, ["iv"] =0.27},
    {["name"] = "Cobalt", ["r"] = 35, ["g"] = 56, ["b"] = 201, ["i"] =0.2, ["ii"] =0.21, ["iii"] =0.22, ["iv"] =0.23},
    {["name"] = "Sienna", ["r"] = 187, ["g"] = 125, ["b"] = 53, ["i"] =0, ["ii"] =0.05, ["iii"] =0.1, ["iv"] =0.15}
}

local oclearState = -1
local gaugetype = -1
--------------------------------------------------------------------------------
function draw_liveforce()
    --Nutchapol's LiveForce v1
    --https://github.com/NutchapolSal/files/tree/master/usc/liveforce

    local grade, gradeRate, badge, badgeRate --informations
    local force, maxForce, replayForce--force stuffs
    local badgeSize, gradeSize, gradew, gradeh, badgew, badgeh --graphic stuffs
    local prefix, diff --force diff stuffs
    local mainx, mainy, mainx2, mainy2, subx, suby, subx2, suby2, maxx, maxy, maxx2, maxy2, clsx, clsy, clsx2, clsy2
    local class, clv, cr, cg, cb --volforce class stuffs
    local liveforcescale = 0.75

    gfx.Save()

    if gaugetype == -1  then
        if gameplay.gauge > 0.5 then
            gaugetype = 1
        else
            gaugetype = 0
        end
    end

    for i, v in pairs(grades) do
        if score >= v.min then
            grade = v.num
            gradeRate = v.rate
            break
        end
    end

    if gameplay.comboState == 2 then
        badge = 1 --perfect
    elseif gameplay.comboState == 1 then
        badge = 2 --full-combo
    elseif oclearState == 1 then
        badge = 5 --played
    elseif gaugetype == 1 then
        badge = 3 --hard-clear
    else
        badge = 4 --clear
    end

    badgeRate = badges[badge]

    force = ((gameplay.level * 2) * (score / 10000000) * gradeRate * badgeRate) / 100
    if #gameplay.scoreReplays > 0 then replayForce = ((gameplay.level * 2) * (gameplay.scoreReplays[1].currentScore / 10000000) * gradeRate * badgeRate) / 100 end
    maxForce = ((gameplay.level * 2) * 1.05 * badgeRate) / 100 --max possible force for this run

    for i, v in pairs(classes) do
        if force >= v.i then
            class = v.name
            cr = v.r
            cg = v.g
            cb = v.b
            if force >= v.iv then
                clv = "IV"
            elseif force >= v.iii then
                clv = "III"
            elseif force >= v.ii then
                clv = "II"
            else
                clv = "I"
            end
            break
        end
    end

    gradew, gradeh = gfx.ImageSize(gradesimg[grade]) --image size infos
    badgew, badgeh = gfx.ImageSize(badgesimg[badge])
    gradew, gradeh = (gradew / gradeh) * 30, 30 --limit height to 30, scale down proportionally
    badgew, badgeh = (badgew / badgeh) * 30, 30

    gfx.Translate(13, 555)
    gfx.Scale(liveforcescale,liveforcescale)

    gfx.BeginPath()
    gfx.LoadSkinFont("NovaMono.ttf")
    gfx.FontSize(50)
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP)

    mainx, mainy, mainx2, mainy2 = gfx.TextBounds(0, math.max(gradeh, badgeh) - 7, string.sub(string.format("%f", force), 1, 4))
    gfx.FontSize(25)
    subx, suby, subx2, suby2 = gfx.TextBounds(mainx2 + 1, 43, string.sub(string.format("%f", force), 5))
    maxx, maxy, maxx2, maxy2 = gfx.TextBounds(0, suby2, string.sub(string.format("%f", maxForce), 1, 4))
    clsx, clsy, clsx2, clsy2 = gfx.TextBounds(0, maxy2, class .. " " .. clv)

    --bg
    gfx.FillColor(0, 0, 0, 128)
    gfx.DrawRect(RECT_FILL, -13, -13, subx2 + 26, clsy2 + 16)

    --main force number
    gfx.FillColor(255, 255, 255)
    gfx.FontSize(50)
    gfx.Text(string.sub(string.format("%f", force), 1, 4), 0, math.max(gradeh, badgeh) - 7)

    --sub force number
    gfx.FontSize(25)
    gfx.FillColor(192, 192, 192)
    gfx.Text(string.sub(string.format("%f", force), 5), mainx2 + 3, 41)

    --max possible force for this run
    gfx.FillColor(255, 255, 255)
    gfx.Text(string.sub(string.format("%f", maxForce), 1, 4), 0, suby2)
    gfx.FillColor(127, 127, 127)
    gfx.Text(string.sub(string.format("%f", maxForce), 5), maxx2, suby2)

    --classes
    gfx.FillColor(cr, cg, cb)
    gfx.FontSize(20)
    gfx.Text(class .. " " .. clv, 0, maxy2)

    --images
    gfx.FillColor(255, 255, 255, 255)
    gfx.DrawRect(badgesimg[badge], 0, 0, badgew, badgeh)
    gfx.DrawRect(gradesimg[grade], subx2 - gradew, 0, gradew, gradeh)

    gfx.Restore()
end
-- -------------------------------------------------------------------------- --
function draw_funshits(deltaTime)
    fsRemain()
    fsRipples(deltaTime)
    fsPressHist(deltaTime)
    fsInvaders(deltaTime)
    fsPong(deltaTime)
end
-----
function fsRemain()
    local c = {["x"] = desw/2, ["y"] = 20, ["r"] = 15, ["p"] = gameplay.progress * math.pi * 2} --c is for constants; x,y = center position; r = radius; p = progress as angle
    gfx.Save()
    gfx.StrokeWidth(1)
    gfx.Translate(c.x, c.y)
    gfx.Rotate(math.rad(-90))

    gfx.BeginPath() --center point
    gfx.Circle(0, 0, 1)
    gfx.FillColor(255, 255, 255)
    gfx.Fill()

    gfx.BeginPath() --outer ring
    gfx.Circle(0, 0, c.r)
    gfx.StrokeColor(255, 255, 255, 63)
    gfx.Stroke()

    gfx.BeginPath() --section fill
    gfx.MoveTo(0, 0)
    gfx.Arc(0, 0, c.r, c.p, math.pi * 2, 2) --1 for ccw, 2 for cw
    gfx.ClosePath()
    gfx.FillColor(255, 255, 255, 63)
    gfx.Fill()

    gfx.BeginPath() --section stroke
    gfx.Arc(0, 0, c.r, c.p, math.pi * 2, 2)
    gfx.StrokeColor(255, 255, 255)
    gfx.Stroke()

    gfx.Restore()
end
-----
local btpresses = {}
local fsA, fsB, fsC, fsD, fsL, fsR = false, false, false, false, false, false
function fsRipples(deltaTime)
    if game.GetButtonPressed(0) and not(fsA) then table.insert(btpresses, 1, {["btn"] = 0, ["age"] = 0, ["x"] = 0, ["y"] = 0, ["marked"] = false}) end
    if game.GetButtonPressed(1) and not(fsB) then table.insert(btpresses, 1, {["btn"] = 1, ["age"] = 0, ["x"] = 0, ["y"] = 0, ["marked"] = false}) end
    if game.GetButtonPressed(2) and not(fsC) then table.insert(btpresses, 1, {["btn"] = 2, ["age"] = 0, ["x"] = 0, ["y"] = 0, ["marked"] = false}) end
    if game.GetButtonPressed(3) and not(fsD) then table.insert(btpresses, 1, {["btn"] = 3, ["age"] = 0, ["x"] = 0, ["y"] = 0, ["marked"] = false}) end
    if game.GetButtonPressed(4) and not(fsL) then table.insert(btpresses, 1, {["btn"] = 4, ["age"] = 0, ["x"] = 0, ["y"] = 0, ["marked"] = false}) end
    if game.GetButtonPressed(5) and not(fsR) then table.insert(btpresses, 1, {["btn"] = 5, ["age"] = 0, ["x"] = 0, ["y"] = 0, ["marked"] = false}) end

    fsA = game.GetButtonPressed(0)
    fsB = game.GetButtonPressed(1)
    fsC = game.GetButtonPressed(2)
    fsD = game.GetButtonPressed(3)
    fsL = game.GetButtonPressed(4)
    fsR = game.GetButtonPressed(5)

    local deletenum = 0

    gfx.Save()
    gfx.Translate(1267,707)
    gfx.FillColor(0, 0, 0, 128) --transparent bg
    gfx.DrawRectBool(true, false, -128, -72, 128, 72)
    gfx.Scissor(-128, -72, 128, 72)

    local agespeed = gameplay.bpm * (1 / 60)

    for i, v in pairs(btpresses) do
        if v.btn == 0 then
            gfx.StrokeColor(255, 223, 223)
        elseif v.btn == 1 then
            gfx.StrokeColor(223, 255, 223)
        elseif v.btn == 2 then
            gfx.StrokeColor(223, 223, 255)
        elseif v.btn == 3 then
            gfx.StrokeColor(255, 255, 223)
        elseif v.btn == 4 then
            gfx.StrokeColor(255, 128, 0)
        else
            gfx.StrokeColor(255, 175, 95)
        end

        if v.age == 0 then
            v.x = math.random()
            v.y = math.random()
        end

        gfx.StrokeWidth(math.max(1 - v.age) * 3)
        gfx.DrawCircleBool(false, true, v.x * -128, v.y * -72, v.age * 20)

        v.age = v.age + (agespeed * deltaTime)
        if v.age > 1 and not(v.marked) then
            deletenum = deletenum + 1
            v.marked = true
        end
    end

    while deletenum ~= 0 do
        table.remove(btpresses, #btpresses)
        deletenum = deletenum - 1
    end
    gfx.ResetScissor()
    gfx.Restore()
end
-----
local pressHist = {}
local phTime = 0
function fsPressHist(deltaTime)
    gfx.Save()
    gfx.Translate(1252,130)
    local smax = 0.0065 --stolen from condisp

    if phTime > 0.005 and outroTimer == 0 then
        table.insert(pressHist, 1, {["s"] = game.GetButtonPressed(6), ["a"] = game.GetButtonPressed(0), ["b"] = game.GetButtonPressed(1), ["c"] = game.GetButtonPressed(2), ["d"] = game.GetButtonPressed(3), ["fl"] = game.GetButtonPressed(4), ["fr"] = game.GetButtonPressed(5), ["l"] = lspeed, ["r"] = rspeed})
        phTime = phTime - 0.005 + deltaTime
    else
        phTime = phTime + deltaTime
    end

    for i, v in pairs(pressHist) do

        if v.l < 0 then
            gfx.FillLaserColor(1, math.min(math.abs(v.l) * (255 / smax),255))
        else
            gfx.FillLaserColor(2, math.min(math.abs(v.l) * (255 / smax),255))
        end
        gfx.DrawRectBool(true, false, 0, (i - 1) * 1.001, 3, 1.001)

        if v.r < 0 then
            gfx.FillLaserColor(1, math.min(math.abs(v.r) * (255 / smax),255))
        else
            gfx.FillLaserColor(2, math.min(math.abs(v.r) * (255 / smax),255))
        end
        gfx.DrawRectBool(true, false, 20, (i - 1) * 1.001, 3, 1.001)

        gfx.FillColor(0, 0, 255)
        gfx.DrawRectBool(v.s, false, 4, (i - 1) * 1.001, 16, 1.001)

        gfx.FillColor(255, 128, 0)
        gfx.DrawRectBool(v.fl, false, 4.5, (i - 1) * 1.001, 7, 1.001)
        gfx.DrawRectBool(v.fr, false, 12.5, (i - 1) * 1.001, 7, 1.001)

        gfx.FillColor(255, 255, 255)
        gfx.DrawRectBool(v.a, false, 4.5, (i - 1) * 1.001, 3, 1.001)
        gfx.DrawRectBool(v.b, false, 8.5, (i - 1) * 1.001, 3, 1.001)
        gfx.DrawRectBool(v.c, false, 12.5, (i - 1) * 1.001, 3, 1.001)
        gfx.DrawRectBool(v.d, false, 16.5, (i - 1) * 1.001, 3, 1.001)
    end

    if #pressHist > 500 then table.remove(pressHist, #pressHist) end

    gfx.Restore()
end
-----
function fsInvaders(deltaTime)
end
-----
local ballsave = {["x"] = 0.5, ["y"] = 0.5, ["sx"] = 69, ["sy"] = 420, ["r"] = 0} --x and y here are compatible with any window size, x and y are percentage of the window, where the ball is. r is rally count
local paddle = {["b"] = 0.5, ["l"] = 0.5, ["r"] = 0.5} --paddle locations
local pongscore = {["p"] = 0, ["b"] = 0} --scores
local paddlewidth = 15
local ponglineoffset = 0 --for animating dashed middle line
function fsPong(deltaTime)
    gfx.Save()

    local winW, winH = 128, 72 -- window width, window height
    if ballsave.sx == 69 and ballsave.sy == 420 then --initialize ball
        local range = 70
        local a = math.rad(90 - range / 2 + math.random(0, range) + (math.random(0, 1) * 180))
        ballsave.sx = math.sin(a) --convert angle to vectors
        ballsave.sy = math.cos(a) --it's easier for collisions
    end
    local ball = {["x"] = ballsave.x * winW, ["y"] = ballsave.y * winH, ["sx"] = ballsave.sx, ["sy"] = ballsave.sy, ["r"] = ballsave.r} --convert format, x and y are coordinates

    gfx.Translate(1135 - winW, 707 - winH)

    gfx.FillColor(0, 0, 0, 128) --transparent bg
    gfx.DrawRectBool(true, false, -3, 0, winW + 6, winH)

    gfx.StrokeColor(255, 255, 255, 128) --goal lines
    gfx.Scissor(-3, 1, winW + 6, winH - 2)
    gfx.DrawRectBool(false, true, -3, 0, winW + 6, winH)

    gfx.StrokeColor(255, 255, 255) --walls
    gfx.Scissor(-3, 0, winW + 6, winH)
    gfx.DrawRectBool(false, true, -4, 0, winW + 8, winH)
    gfx.ResetScissor()

    gfx.FillColor(255, 255, 255) --ball
    gfx.DrawCircleBool(true, false, ball.x, ball.y, 1.5)

    gfx.FillLaserColor(1, 255) --paddles, left knob
    gfx.DrawRectBool(true, false, winW - 1, winH * paddle.l - paddlewidth / 2, 2, paddlewidth)
    gfx.FillLaserColor(2, 255) --right knob
    gfx.DrawRectBool(true, false, winW - 1, winH * paddle.r - paddlewidth / 2, 2, paddlewidth)
    gfx.FillColor(255, 255, 255) -- ai knob
    gfx.DrawRectBool(true, false, -1, winH * paddle.b - paddlewidth / 2, 2, paddlewidth)

    --paddle calculations
    paddle.l = math.max(paddlewidth / 2 / winH, math.min((winH - paddlewidth / 2) / winH , paddle.l + lspeed / winH * 50))
    paddle.r = math.max(paddlewidth / 2 / winH, math.min((winH - paddlewidth / 2) / winH , paddle.r + rspeed / winH * 50))

    -- ai paddle calculations
    -- it's speed is dependent on chart's level
    paddle.b = math.max(paddlewidth / 2 / winH, math.min((winH - paddlewidth / 2) / winH , (paddle.b + (math.max(math.min((ball.y - paddle.b * winH), gameplay.level + 10), -gameplay.level + 10) * deltaTime * (gameplay.level / 20 * 4)) / winH)))

    local ballspeed = gameplay.bpm * (1 / 60) * 20 * ((ball.r + 25) / 25) --ball speed depends on bpm and rally count

    ball.x = ball.x + ball.sx * ballspeed * deltaTime -- update ball location
    ball.y = ball.y + ball.sy * ballspeed * deltaTime

    if outroTimer == 0 then --walls are just a suggestion when it's outro
        if ball.y > winH - 1.5 or ball.y < 1.5 then --if ball bounce wall
            ball.sy = -ball.sy
            ball.y = math.max(math.min(winH - 1.5, ball.y), 1.5)
        end

        -- if ball bounce paddle
        if ball.x > winW - 1.5 and ball.x < winW and (((ball.y < paddle.l * winH + paddlewidth / 2) and (ball.y > paddle.l * winH - paddlewidth / 2)) or ((ball.y < paddle.r * winH + paddlewidth / 2) and (ball.y > paddle.r * winH - paddlewidth / 2))) then
            ball.sx = -ball.sx
            ball.x = math.max(math.min(winW - 1.5, ball.x), 1.5)
            ball.r = ball.r + 1
        elseif ball.x < 1.5 and ball.x > 0 and (ball.y < paddle.b * winH + paddlewidth / 2) and (ball.y > paddle.b * winH - paddlewidth / 2) then
            ball.sx = -ball.sx
            ball.x = math.max(math.min(winW - 1.5, ball.x), 1.5)
            ball.r = ball.r + 1
        end

        --if ball touch goal lines
        if ball.x > winW - -3 or ball.x < -3 then
            if ball.x < winW / 2 then
                pongscore.p = pongscore.p + 1
            else
                pongscore.b = pongscore.b + 1
            end

            ball.x = winW / 2 --re init ball
            ball.y = winH / 2
            local range = 70
            local a = math.rad(90 - range / 2 + math.random(0, range) + (math.random(0, 1) * 180))
            ball.sx = math.sin(a)
            ball.sy = math.cos(a)
            ball.r = 0
        end
    end

    -- dashed middle line
    ponglineoffset = (ponglineoffset + gameplay.bpm * (1 / 60) * deltaTime * 10 + ball.r / 300) % 10

    do --same logic with the old crit line logic
        local numpieces = 1 + math.ceil(winH / 10)
        gfx.Scissor(0, 0, winW, winH)
        for i = 1, numpieces do
            gfx.FillColor(255,255,255, 64)
            gfx.DrawRectBool(true, false, winW / 2 - 0.5, (i - 1) * 10 + ponglineoffset - 5, 1, 5)
        end
        gfx.ResetScissor()
    end

    -- texts
    gfx.FontSize(15)
    gfx.FillColor(255, 255, 255, 255)
    gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_TOP)
    gfx.Text(pongscore.b, (winW / 2) - 5, 5)
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP)
    gfx.Text(pongscore.p, (winW / 2) + 5, 5)
    gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_BASELINE)
    gfx.Text(ball.r, winW / 2, winH - 5)

    if outroTimer ~= 0 then
        gfx.FillColor(0, 0, 0, 128) --transparent bg
        gfx.DrawRectBool(true, false, -3, 0, winW + 6, winH)

        gfx.FontSize(30)
        local wintext
        if pongscore.b == pongscore.p then
            wintext = "DRAW"
        elseif pongscore.b > pongscore.p then
            wintext = "LOSE"
        else
            wintext = "WIN"
        end
        gfx.FillColor(255, 255, 255)
        gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_MIDDLE)
        gfx.Text(wintext, winW / 2, winH / 2)
    end

    ballsave = {["x"] = ball.x / winW, ["y"] = ball.y / winH, ["sx"] = ball.sx, ["sy"] = ball.sy, ["r"] = ball.r}
    gfx.Restore()
end
-- -------------------------------------------------------------------------- --
function draw_infobar()
    local infotext
    if gameplay.demoMode then
        infotext = " DEMO -       -"
    elseif gameplay.autoplay then
        infotext = " AUTO -       -"
    else
        return
    end

    gfx.FillColor(0, 0, 0, 192)
    gfx.DrawRectBool(true, false, 0, 0, desw, 25)

    gfx.FontSize(25)
    gfx.FillColor(255, 255, 255)
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP)
    do
        local x1, y1, x2 = gfx.TextBounds(0, 0, infotext)
        local numPieces = 1 + math.ceil(desw / x2)
        local startOffset = x2 * ((timer * 0.3) % 1)
        for i = 0, numPieces, 1 do
            gfx.Text(infotext, ((i - 1) * x2) + startOffset, 0)
        end
    end
end
-- -------------------------------------------------------------------------- --
local startboxScissor = 0
local introlock = false
local lastBtD = false
function draw_startbox(deltaTime)
    local function sbGButton(bt)
        return game.GetButton(bt) and game.GetButton(6)
    end

    do
        local deltaTime = deltaTime * 5
        if sbGButton(6) then
            startboxScissor = math.min(startboxScissor + deltaTime, 1)
        else
            startboxScissor = math.max(startboxScissor - deltaTime, 0)
        end
        if startboxScissor == 0 then
            return
        end
    end

    if lastBtD ~= sbGButton(3) and lastBtD then
        if introLock then
            introLock = false
        else
            introLock = true
        end
    end
    lastBtD = sbGButton(3)


    local startboxList = {}
    local function startboxInsert(ltext, rtext, lr, lg, lb, rr, rg, rb)
        local ltable = {}
        ltable.t = ltext
        if lr then
            ltable.r = lr
            ltable.g = lg
            ltable.b = lb
        end

        local rtable = {}
        rtable.t = rtext
        if rr then
            rtable.r = rr
            rtable.g = rg
            rtable.b = rb
        end
        table.insert(startboxList, {["l"] = ltable, ["r"] = rtable})
    end

    if sbGButton(1) or sbGButton(2) or not(sbGButton(6)) then
        startboxInsert("HiSpeed", string.format("%.0f x %.1f = %.0f", gameplay.bpm, gameplay.hispeed, gameplay.bpm * gameplay.hispeed))
    else
        startboxInsert("HiSpeed", string.format("%.0f x %.1f = %.0f", gameplay.bpm, gameplay.hispeed, gameplay.bpm * gameplay.hispeed), 128, 255, 128, 128, 255, 128)
    end
    startboxInsert()
    if gameplay.demoMode then
        startboxInsert("Early/Late Position", "N/A in Demo")
    elseif introTimer <= 0 then
        startboxInsert("Early/Late Position", "N/A after intro")
    elseif sbGButton(0) then
        startboxInsert("Early/Late Position", "BT-A", 128, 255, 128, 128, 255, 128)
    else
        startboxInsert("Early/Late Position", "BT-A")
    end
    startboxInsert("  " .. earlatePos)
    startboxInsert()
    startboxInsert("Hidden/Sudden")
    if sbGButton(1) then
        startboxInsert("> Cutoff", "Hold BT-B  ", 128, 255, 128, 128, 255, 128)
        startboxInsert("  Fade", "Hold BT-C  ")
    elseif sbGButton(2) then
        startboxInsert("  Cutoff", "Hold BT-B  ")
        startboxInsert("> Fade", "Hold BT-C  ", 128, 255, 128, 128, 255, 128)
    else
        startboxInsert("  Cutoff", "Hold BT-B  ")
        startboxInsert("  Fade", "Hold BT-C  ")
    end
    if sbGButton(1) or sbGButton(2) then
        local r0, g0, b0 = game.GetLaserColor(0)
        local r1, g1, b1 = game.GetLaserColor(1)
        startboxInsert("    VOL-L | Hidden", "Sudden | VOL-R    ", r0, g0, b0, r1, g1, b1)
    end
    startboxInsert("[hidsudbar]")
    do
        local r0, g0, b0 = game.GetLaserColor(0)
        local r1, g1, b1 = game.GetLaserColor(1)
        if sbGButton(1) then
            startboxInsert(string.format("    %.1f%%", gameplay.hiddenCutoff * 100), string.format("%.1f%%    ", gameplay.suddenCutoff * 100), r0, g0, b0, r1, g1, b1)
        elseif sbGButton(2) then
            startboxInsert(string.format("    %.1f%%", gameplay.hiddenFade * 100), string.format("%.1f%%    ", gameplay.suddenFade * 100), r0, g0, b0, r1, g1, b1)
        end
    end

    if introLock then
        startboxInsert("introLock")
    end

    local height
    local textheight
    do
        gfx.LoadSkinFont("slant.ttf")
        gfx.FontSize(25)
        gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP)
        local x1, y1, x2, y2 = gfx.TextBounds(0, 0, "I")
        textheight = y2
    end

    local width = desw / 3
    height = textheight * #startboxList
    local textpad = 10 -- text padding

    gfx.Save()
    gfx.Translate((desw - width) / 2, (desh - height) / 2)
    do
        local scissorWidth = width * startboxScissor * 3
        local scissorHeight = height * startboxScissor * 1.2
        gfx.Scissor((width / 2) - (scissorWidth / 2), (height / 2) - (scissorHeight / 2), scissorWidth, scissorHeight)
    end

    gfx.FillColor(0, 0, 255, 32)
    do
        local textpad = textpad / 2
        gfx.DrawRectBool(true, false, 0, 0 - textpad, width, height + (textpad * 2))
    end

    local function drawHidSudBar(texty)
        gfx.Save()
        local hidsudWidth = width - (textpad * 5)

        gfx.Translate(textpad * 2.5, texty + (textheight - (textheight / 3)))
        gfx.IntersectScissor(-1, -(textheight / 3), hidsudWidth + 2, textheight / 3 * 2)
        gfx.FillColor(64, 64, 64)
        gfx.DrawRectBool(true, false, 0, 0, hidsudWidth, textheight / 3)

        local r0, g0, b0 = game.GetLaserColor(0)
        local r1, g1, b1 = game.GetLaserColor(1)

        local cRgbMul, fRgbMul = 1, 1 -- color multipliers, c for cutoff, f for fade
        if sbGButton(1) then
            fRgbMul = 0.5
        elseif sbGButton(2) then
            cRgbMul = 0.5
        else
            cRgbMul = 0.5
            fRgbMul = 0.5
        end

        if gameplay.suddenCutoff < gameplay.hiddenCutoff then
            -- hidden
            gfx.GradientColors(math.ceil(r0 * fRgbMul), math.ceil(g0 * fRgbMul), math.ceil(b0 * fRgbMul), 255, math.ceil(r0 * fRgbMul), math.ceil(g0 * fRgbMul), math.ceil(b0 * fRgbMul), 0)
            gfx.FillPaint(gfx.LinearGradient(hidsudWidth * gameplay.hiddenCutoff, 0, (hidsudWidth * gameplay.hiddenCutoff) + (hidsudWidth * gameplay.hiddenFade), 0))
            gfx.DrawRectBool(true, false, hidsudWidth * gameplay.suddenCutoff, -(textheight / 3 / 2), ((gameplay.hiddenCutoff - gameplay.suddenCutoff) * hidsudWidth) + (hidsudWidth * gameplay.hiddenFade), textheight / 3 / 2)

            gfx.FillColor(r0 * fRgbMul, g0 * fRgbMul, b0 * fRgbMul)
            gfx.DrawRectBool(true, false, (hidsudWidth * gameplay.hiddenCutoff) + (hidsudWidth * gameplay.hiddenFade), -(textheight / 3), 1, (textheight / 3))

            --sudden
            gfx.GradientColors(math.ceil(r1 * fRgbMul), math.ceil(g1 * fRgbMul), math.ceil(b1 * fRgbMul), 255, math.ceil(r1 * fRgbMul), math.ceil(g1 * fRgbMul), math.ceil(b1 * fRgbMul), 0)
            gfx.FillPaint(gfx.LinearGradient(hidsudWidth * gameplay.suddenCutoff, 0, (gameplay.suddenCutoff * hidsudWidth) - (gameplay.suddenFade * hidsudWidth), 0))
            gfx.DrawRectBool(true, false, (gameplay.suddenCutoff * hidsudWidth) - (gameplay.suddenFade * hidsudWidth), -(textheight / 3), ((gameplay.hiddenCutoff - gameplay.suddenCutoff) * hidsudWidth) + (hidsudWidth * gameplay.suddenFade), textheight / 3 / 2)

            gfx.FillColor(r1 * fRgbMul, g1 * fRgbMul, b1 * fRgbMul)
            gfx.DrawRectBool(true, false, (hidsudWidth * gameplay.suddenCutoff) - (hidsudWidth * gameplay.suddenFade), -(textheight / 3), 1, (textheight / 3))
        else
            -- hidden
            gfx.GradientColors(math.ceil(r0 * fRgbMul), math.ceil(g0 * fRgbMul), math.ceil(b0 * fRgbMul), 255, math.ceil(r0 * fRgbMul), math.ceil(g0 * fRgbMul), math.ceil(b0 * fRgbMul), 0)
            gfx.FillPaint(gfx.LinearGradient((hidsudWidth * gameplay.hiddenCutoff) - (hidsudWidth * gameplay.hiddenFade), 0, hidsudWidth * gameplay.hiddenCutoff, 0))
            gfx.DrawRectBool(true, false, 0, -(textheight / 3 / 2), hidsudWidth * gameplay.hiddenCutoff, textheight / 3 / 2)

            gfx.FillColor(r0 * fRgbMul, g0 * fRgbMul, b0 * fRgbMul)
            gfx.DrawRectBool(true, false, (hidsudWidth * gameplay.hiddenCutoff) - (hidsudWidth * gameplay.hiddenFade), -(textheight / 3), 1, (textheight / 3))

            -- sudden
            gfx.GradientColors(math.ceil(r1 * fRgbMul), math.ceil(g1 * fRgbMul), math.ceil(b1 * fRgbMul), 255, math.ceil(r1 * fRgbMul), math.ceil(g1 * fRgbMul), math.ceil(b1 * fRgbMul), 0)
            gfx.FillPaint(gfx.LinearGradient((hidsudWidth * gameplay.suddenCutoff) + (hidsudWidth * gameplay.suddenFade), 0, hidsudWidth * gameplay.suddenCutoff, 0))
            gfx.DrawRectBool(true, false, hidsudWidth * gameplay.suddenCutoff, -(textheight / 3), hidsudWidth - (hidsudWidth * gameplay.suddenCutoff), textheight / 3 / 2)

            gfx.FillColor(r1 * fRgbMul, g1 * fRgbMul, b1 * fRgbMul)
            gfx.DrawRectBool(true, false, (hidsudWidth * gameplay.suddenCutoff) + (hidsudWidth * gameplay.suddenFade), -(textheight / 3), 1, (textheight / 3))
        end

        if gameplay.suddenCutoff < gameplay.hiddenCutoff then -- for when it blocks the middle
            gfx.Save()
            gfx.IntersectScissor((hidsudWidth * gameplay.suddenCutoff), -(textheight / 3), (hidsudWidth * (gameplay.hiddenCutoff - gameplay.suddenCutoff)) + 1.5, (textheight / 3) * 2)
        end

        gfx.FillColor(r0 * cRgbMul, g0 * cRgbMul, b0 * cRgbMul)
        gfx.DrawRectBool(true, false, 0, 0, hidsudWidth * gameplay.hiddenCutoff, textheight / 3) -- hidden fill
        gfx.DrawRectBool(true, false, hidsudWidth * gameplay.hiddenCutoff, -(textheight / 3), 1, (textheight / 3) * 2) -- hidden cursor

        gfx.FillColor(r1 * cRgbMul, g1 * cRgbMul, b1 * cRgbMul)
        gfx.DrawRectBool(true, false, hidsudWidth - (hidsudWidth * (1 - gameplay.suddenCutoff)), 0, hidsudWidth * (1 - gameplay.suddenCutoff), textheight / 3) --sudden fill
        gfx.DrawRectBool(true, false, hidsudWidth * gameplay.suddenCutoff, -(textheight / 3), 1, (textheight / 3) * 2) --sudden cursor

        if gameplay.suddenCutoff < gameplay.hiddenCutoff then
            gfx.Restore()
        end

        gfx.Restore()
    end


    gfx.LoadSkinFont("slant.ttf")
    gfx.FontSize(25)
    for i, v in ipairs(startboxList) do
        local texty = (i - 1) * textheight
        for j, w in pairs(v) do
            local textx
            if j == "r" then
                gfx.TextAlign(gfx.TEXT_ALIGN_RIGHT + gfx.TEXT_ALIGN_TOP)
                textx = width - textpad
            else
                gfx.TextAlign(gfx.TEXT_ALIGN_LEFT + gfx.TEXT_ALIGN_TOP)
                textx = textpad
            end

            if w.r then
                gfx.FillColor(w.r, w.g, w.b)
            else
                gfx.FillColor(255, 255, 255)
            end

            if w.t == "[hidsudbar]" then
                drawHidSudBar(texty)
            elseif w.t then
                gfx.Text(w.t, textx, texty)
            end
        end
    end

    gfx.Restore()
end
-- -------------------------------------------------------------------------- --
local lcdtimer = 0
local lcdNoReTimer = 0
function sendtolcd(deltaTime)
        lcdNoReTimer = lcdNoReTimer + (deltaTime * 10)
        lcdtimer = lcdtimer + (deltaTime * 10)
        local lcdNRTround = math.ceil(lcdNoReTimer)
        local text = "\n\n\n" .. gameplay.artist .. "\t" .. gameplay.title

        if lcdtimer > 1 then
            scriptfile = io.open("\\\\.\\COM201", "w+")
            scriptfile:write(text:sub(lcdNRTround, lcdNRTround))
            scriptfile:close()
            lcdtimer = lcdtimer - 1
            if lcdNRTround == text:len() then
                sentlcd = true
            end
        end
end
-- -------------------------------------------------------------------------- --
-- draw_alerts:                                                               --
function draw_alerts(deltaTime)
    alertTimers[1] = math.max(alertTimers[1] - deltaTime,-2)
    alertTimers[2] = math.max(alertTimers[2] - deltaTime,-2)
    if alertTimers[1] > 0 then --draw left alert
        gfx.Save()
        local posx = desw / 2 - 350
        local posy = desh * critLinePos[1] - 135
        if portrait then
            posy = desh * critLinePos[2] - 135
            posx = 65
        end
        gfx.Translate(posx,posy)
        r,g,b = game.GetLaserColor(0)
        local alertScale = (-(alertTimers[1] ^ 2.0) + (1.5 * alertTimers[1])) * 5.0
        alertScale = math.min(alertScale, 1)
        gfx.Scale(1, alertScale)
        gfx.BeginPath()
        gfx.RoundedRectVarying(-50,-50,100,100,20,0,20,0)
        gfx.StrokeColor(r,g,b)
        gfx.FillColor(20,20,20)
        gfx.StrokeWidth(2)
        gfx.Fill()
        gfx.Stroke()
        gfx.BeginPath()
        gfx.FillColor(r,g,b)
        gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_MIDDLE)
        gfx.FontSize(90)
        gfx.Text("L",0,0)
        gfx.Restore()
    end
    if alertTimers[2] > 0 then --draw right alert
        gfx.Save()
        local posx = desw / 2 + 350
        local posy = desh * critLinePos[1] - 135
        if portrait then
            posy = desh * critLinePos[2] - 135
            posx = desw - 65
        end
        gfx.Translate(posx,posy)
        r,g,b = game.GetLaserColor(1)
        local alertScale = (-(alertTimers[2] ^ 2.0) + (1.5 * alertTimers[2])) * 5.0
        alertScale = math.min(alertScale, 1)
        gfx.Scale(1, alertScale)
        gfx.BeginPath()
        gfx.RoundedRectVarying(-50,-50,100,100,0,20,0,20)
        gfx.StrokeColor(r,g,b)
        gfx.FillColor(20,20,20)
        gfx.StrokeWidth(2)
        gfx.Fill()
        gfx.Stroke()
        gfx.BeginPath()
        gfx.FillColor(r,g,b)
        gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_MIDDLE)
        gfx.FontSize(90)
        gfx.Text("R",0,0)
        gfx.Restore()
    end
end

function change_earlatepos()
	if earlatePos == "top" then
		earlatePos = "off"
	elseif earlatePos == "off" then
		earlatePos = "bottom"
	elseif earlatePos == "bottom" then
		earlatePos = "middle"
	elseif earlatePos == "middle" then
		earlatePos = "top"
	end
	game.SetSkinSetting("earlate_position", earlatePos)
end

-- -------------------------------------------------------------------------- --
-- render_intro:                                                              --
local bta_last = false
function render_intro(deltaTime)
    if gameplay.demoMode then
        introTimer = 0
        return true
    end
    if not game.GetButton(game.BUTTON_STA) or introTimer >= 1 then
        introTimer = introTimer - deltaTime
		earlateTimer = 0
    end

	if game.GetButton(game.BUTTON_STA) or introLock then
		earlateTimer = 1
        if introTimer < 1 then
            introTimer = 1
        end
		if (not bta_last) and game.GetButton(game.BUTTON_BTA) then
			change_earlatepos()
		end
	end
	bta_last = game.GetButton(game.BUTTON_BTA)
    introTimer = math.max(introTimer, 0)

    return introTimer <= 0
end
-- -------------------------------------------------------------------------- --
-- render_outro:                                                              --
function render_outro(deltaTime, clearState)
    if clearState == 0 then return true end
    if not gameplay.demoMode then
        gfx.ResetTransform()
        gfx.BeginPath()
        gfx.Rect(0,0,resx,resy)
        gfx.FillColor(0,0,0, math.floor(127 * math.min(outroTimer, 1)))
        gfx.Fill()
        gfx.Scale(scale,scale)
        gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_MIDDLE)
        gfx.FillColor(255,255,255, math.floor(255 * math.min(outroTimer, 1)))
        gfx.LoadSkinFont("NovaMono.ttf")
        gfx.FontSize(70)
        gfx.Text(clearTexts[clearState], desw / 2, desh / 2)
        outroTimer = outroTimer + deltaTime
        return outroTimer > 2, 1 - outroTimer
    else
        outroTimer = outroTimer + deltaTime
        return outroTimer > 2, 1
    end

end
-- -------------------------------------------------------------------------- --
-- update_score:                                                              --
function update_score(newScore)
    score = newScore
end
-- -------------------------------------------------------------------------- --
-- update_combo:                                                              --
function update_combo(newCombo)
    combo = newCombo
    comboScale = 1.5
end
-- -------------------------------------------------------------------------- --
-- near_hit:                                                                  --
function near_hit(wasLate) --for updating early/late display
    late = wasLate
    earlateTimer = 0.75
end
-- -------------------------------------------------------------------------- --
-- laser_alert:                                                               --
function laser_alert(isRight) --for starting laser alert animations
    if isRight and alertTimers[2] < -1.5 then
        alertTimers[2] = 1.5
    elseif alertTimers[1] < -1.5 then
        alertTimers[1] = 1.5
    end
end


-- ======================== Start mutliplayer ========================

json = require "json"

local normal_font = game.GetSkinSetting('multi.normal_font')
if normal_font == nil then
    normal_font = 'NotoSans-Regular.ttf'
end
local mono_font = game.GetSkinSetting('multi.mono_font')
if mono_font == nil then
    mono_font = 'NovaMono.ttf'
end

local users = nil

function init_tcp()
    Tcp.SetTopicHandler("game.scoreboard", function(data)
        users = {}
        for i, u in ipairs(data.users) do
            table.insert(users, u)
        end
    end)
end


-- Hook the render function and draw the scoreboard
local real_render = render
render = function(deltaTime)
    real_render(deltaTime)
    draw_users(deltaTime)
end

-- Update the users in the scoreboard
function score_callback(response)
    if response.status ~= 200 then
        error()
        return
    end
    local jsondata = json.decode(response.text)
    users = {}
    for i, u in ipairs(jsondata.users) do
        table.insert(users, u)
    end
end

-- Render scoreboard
function draw_users(detaTime)
    if (users == nil) then
        return
    end

    local yshift = 0

    -- In portrait, we draw a banner across the top
    -- The rest of the UI needs to be drawn below that banner
    if portrait then
        local bannerWidth, bannerHeight = gfx.ImageSize(topFill)
        yshift = desw * (bannerHeight / bannerWidth)
        gfx.Scale(0.7, 0.7)
    end

    gfx.Save()

    -- Add a small margin at the edge
    gfx.Translate(5,yshift+200)

    -- Reset some text related stuff that was changed in draw_state
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT)
    gfx.FontSize(35)
    gfx.FillColor(255, 255, 255)
    local yoff = 0
    if portrait then
        yoff = 75;
    end
    local rank = 0
    for i, u in ipairs(users) do
        gfx.FillColor(255, 255, 255)
        local score_big = string.format("%04d",math.floor(u.score/1000));
        local score_small = string.format("%03d",u.score%1000);
        local user_text = '('..u.name..')';

        local size_big = 40;
        local size_small = 28;
        local size_name = 30;

        if u.id == gameplay.user_id then
            size_big = 48
            size_small = 32
            size_name = 40
            rank = i;
        end

        gfx.LoadSkinFont(mono_font)
        gfx.FontSize(size_big)
        gfx.Text(score_big, 0, yoff);
        local xmin,ymin,xmax,ymax_big = gfx.TextBounds(0, yoff, score_big);
        xmax = xmax + 7

        gfx.FontSize(size_small)
        gfx.Text(score_small, xmax, yoff);
        xmin,ymin,xmax,ymax = gfx.TextBounds(xmax, yoff, score_small);
        xmax = xmax + 7

        if u.id == gameplay.user_id then
            gfx.FillColor(237, 240, 144)
        end

        gfx.LoadSkinFont(normal_font)
        gfx.FontSize(size_name)
        gfx.Text(user_text, xmax, yoff)

        yoff = ymax_big + 15
    end

    gfx.Restore()
end

function satisfy_luacheck()
    if 1 == 2 then
        update_score()
        update_combo()
        near_hit()
        laser_alert()
        UpdateButtonStatesAfterProcessed()
        render()
        render_crit_overlay()
        render_crit_base()
        render_intro()
        render_outro()
        satisfy_luacheck()
    end
end