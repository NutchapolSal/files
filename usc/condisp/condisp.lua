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
local lspeed, rspeed, lfirst, rfirst, llast, rlast = 0, 0, 0, 0, 0, 0
local ls, rs = {0}, {0}
--------------------------------------------------------------------------------
function draw_condisp()
	--Nutchapol's CONtroller DISPlay v3
	--https://github.com/NutchapolSal/files/tree/master/usc/condisp
	--total wxh= 227x108
	--margins: 13px
	--with margins=253x134
	--top left anchor, does not include margin
	gfx.Save()
	
	local posx = 13 --13 = attached to left, desw - 183 or 1097 = attached to right
	local posy = desh - 121 --13 = attached to top, desh - 121 or 599 = attached to bottom
    local smax = 0.0065 --max speed for knob
	
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
	
    gfx.Save()
	gfx.Translate(114, 9)
	gfx.Rotate(math.rad(45))
	gfx.StrokeColor(0, 0, 128) --start
	gfx.FillColor(0, 0, 255)
	gfx.DrawRectBool(game.GetButtonPressed(6), true, -9, -9, 19, 19)
    gfx.Restore()	
	
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
    
    lspeed = 0 --reset knobspeed
    rspeed = 0

    for i, v in pairs(ls) do --sum the table
        lspeed = lspeed + v
    end
    for i, v in pairs(rs) do
        rspeed = rspeed + v
    end
	
    lspeed = lspeed / #ls --averaging last x frames of knobspeed
	rspeed = rspeed / #rs
	
    debox(lspeed)
    debox(rspeed)


	gfx.StrokeColor(game.GetLaserColor(0))
	gfx.FillLaserColor(1, math.min(math.abs(lspeed) * (255 / smax),255))--set fill color to knob color w/ transparency. opaque = u spin knob, can't see knob fill = u no spin knob
	gfx.DrawLine(9.5, 3.5, lspeed * (16 / smax), 0, 2) --the bar
	gfx.DrawCircleBool(true, true, 8.5, 13.5, 9) --the knob circle
	
	gfx.StrokeColor(game.GetLaserColor(1))
	gfx.FillLaserColor(2, math.min(math.abs(rspeed) * (255 / smax),255))
	gfx.DrawLine(218.5, 3.5, rspeed * (16 / smax), 0, 2)
	gfx.DrawCircleBool(true, true, 217.5, 13.5, 9)
	
    table.insert(ls, 1, ls1) --table management
    table.insert(rs, 1, rs1)
    if #ls > 50 then table.remove(ls, #ls) end --remove off limit entries
    if #rs > 50 then table.remove(rs, #rs) end

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
	if count == 0 then else --no looking at nil values
        local j = 1 --y pos in case a score gets killed(look below) so it wont leave holes in the graph
		for i = 1, count, 1 do --for each past yous

            if i == 1 then --no looking at nil values, and also i dont need you to die so
            elseif gameplay.scoreReplays[i] == 10000000 then --only 1 perfect can exist in this score graph
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