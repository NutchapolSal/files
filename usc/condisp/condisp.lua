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
function draw_condisp()
	--Nutchapol's CONtroller DISPlay v2
	--https://github.com/NutchapolSal/files/tree/master/usc/condisp
	--total wxh= 227x108
	--margins: 13px
	--with margins=253x134
	--top left anchor, does not include margin
	gfx.Save()
	
	local posx = 13 --13 = attached to left, desw - 183 or 1097 = attached to right
	local posy = desh - 121 --13 = attached to top, desh - 121 or 599 = attached to bottom
	
	lfirst = game.GetKnob(0)--get some
	rfirst = game.GetKnob(1)--knob measurements
	
	--intro animations
	--select one & remove comment, comment out using -- or delete the others
	
	--fly in from left
	gfx.Translate(((posx + 253) * (1 - math.max(introTimer - 1, 0))) - 253, posy)
	--fly in from top
	--gfx.Translate(posx,((posy + 134) * (1 - math.max(introTimer - 1, 0))) - 134)
	--fly in from right
	--gfx.Translate(posx + ((desw - posx) * math.max(introTimer - 1, 0)), posy)
	--fly in from bottom
	--gfx.Translate(posx,posy + ((desh - posy) * math.max(introTimer - 1, 0)))
	
	gfx.FillColor(0, 0, 0, 128) --transparent bg
	gfx.DrawRectBool(true, false, -13, -13, 253, 134)
	
	gfx.Translate(114, 9)
	gfx.Rotate(math.rad(45))
	gfx.StrokeColor(0, 0, 128) --start
	gfx.FillColor(0, 0, 255)
	gfx.DrawRectBool(game.GetButtonPressed(6), true, -9, -9, 19, 19)
	gfx.Rotate(math.rad(-45))
	gfx.Translate(-114, -9)
	
	
	gfx.StrokeColor(255, 255, 255) --bt
	gfx.FillColor(0, 128, 255)
	gfx.DrawRectBool(game.GetButtonPressed(0), true, 28, 36, 36, 36)
	gfx.DrawRectBool(game.GetButtonPressed(1), true, 73, 36, 36, 36)
	gfx.DrawRectBool(game.GetButtonPressed(2), true, 118, 36, 36, 36)
	gfx.DrawRectBool(game.GetButtonPressed(3), true, 163, 36, 36, 36)
	
	gfx.StrokeColor(50, 50, 50) --fx
	gfx.FillColor(255, 0, 0)
	gfx.DrawRectBool(game.GetButtonPressed(4), true, 54, 89, 29, 19)
	gfx.DrawRectBool(game.GetButtonPressed(5), true, 144, 89, 29, 19)
	
	--here starts the knobs
	ls1 = lfirst - llast--calculate knob speeds
	rs1 = rfirst - rlast
	if ls1 < -0.03 then ls1 = 0.029 end--cutoff when the getknob value jumps back to 0 (common)
	if ls1 > 0.03 then ls1 = -0.029 end
	if rs1 < -0.03 then rs1 = 0.029 end
	if rs1 > 0.03 then rs1 = -0.029 end
	lspeed = (ls1 + ls2 + ls3 + ls4 + ls5 + ls6 + ls7 + ls8 + ls9 + ls10)/10 --averaging last 10 freaking frames of knobspeed
	rspeed = (rs1 + rs2 + rs3 + rs4 + rs5 + rs6 + rs7 + rs8 + rs9 + rs10)/10
	
	gfx.StrokeColor(game.GetLaserColor(0))
	gfx.FillLaserColor(1, math.min(math.abs(lspeed) * 25500,255))--set fill color to knob color w/ transparency. opaque = u spin knob, can't see knob fill = u no spin knob
	gfx.DrawLine(9.5, 3.5, lspeed * 1500, 0, 2) --the bar
	gfx.DrawCircleBool(true, true, 8.5, 13.5, 9) --the knob circle
	
	gfx.StrokeColor(game.GetLaserColor(1))
	gfx.FillLaserColor(2, math.min(math.abs(rspeed) * 25500,255))
	gfx.DrawLine(218.5, 3.5, rspeed * 1500, 0, 2)
	gfx.DrawCircleBool(true, true, 217.5, 13.5, 9)
	
	--if you've ever tried calculating the fibonaci sequence on a calculator, this is just like it
	ls10 = ls9
	ls9 = ls8
	ls8 = ls7
	ls7 = ls6
	ls6 = ls5
	ls5 = ls4
	ls4 = ls3
	ls3 = ls2
	ls2 = ls1
	
	rs10 = rs9
	rs9 = rs8
	rs8 = rs7
	rs7 = rs6
	rs6 = rs5
	rs5 = rs4
	rs4 = rs3
	rs3 = rs2
	rs2 = rs1
	
	llast = game.GetKnob(0)--get some
	rlast = game.GetKnob(1)--knob measurements for next time
	gfx.Restore()
end
--------------------------------------------------------------------------------