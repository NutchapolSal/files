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
function draw_condisp()
	--Nutchapol's CONtroller DISPlay v1
	--https://github.com/NutchapolSal/files/tree/master/usc/condisp
	--total wxh= 171x108
	--margins: 13px
	--with margins=197x134
	--top right anchor, does not include margin
	local origx = 13 --13 = attached to left, desw - 183 or 1097 = attached to right
	local origy = desh - 122 --13 = attached to top, desh - 122 or 598 = attached to bottom
	
	--intro animations
	--select one & remove comment, comment out using -- or delete the others
	
	--fly in from left
	posx = ((origx + 197) * (1 - math.max(introTimer - 1, 0))) - 197
	posy= origy
	--fly in from top
	--posx = origx
	--posy = ((origy + 134) * (1 - math.max(introTimer - 1, 0))) - 134
	--fly in from right
	--posx = origx + ((desw - origx) * math.max(introTimer - 1, 0))
	--posy= origy
	--fly in from bottom
	--posx = origx
	--posy= origy + ((desh - origy) * math.max(introTimer - 1, 0))
	
	gfx.FillColor(0, 0, 0, 128) --transparent bg
	gfx.DrawRectBool(true, false, posx - 13, posy - 13, 197, 134)
	
	gfx.StrokeColor(0, 0, 128) --start
	gfx.FillColor(0, 0, 255)
	gfx.DrawRectBool(game.GetButtonPressed(6), true, posx + 76, posy, 19, 19)
	
	gfx.StrokeColor(255, 255, 255) --bt
	gfx.FillColor(0, 128, 255)
	gfx.DrawRectBool(game.GetButtonPressed(0), true, posx, posy + 36, 36, 36)
	gfx.DrawRectBool(game.GetButtonPressed(1), true, posx + 45, posy + 36, 36, 36)
	gfx.DrawRectBool(game.GetButtonPressed(2), true, posx + 90, posy + 36, 36, 36)
	gfx.DrawRectBool(game.GetButtonPressed(3), true, posx + 135, posy + 36, 36, 36)
	
	gfx.StrokeColor(50, 50, 50) --fx
	gfx.FillColor(255, 0, 0)
	gfx.DrawRectBool(game.GetButtonPressed(4), true, posx + 26, posy + 89, 29, 19)
	gfx.DrawRectBool(game.GetButtonPressed(5), true, posx + 116, posy + 89, 29, 19)
end
--------------------------------------------------------------------------------