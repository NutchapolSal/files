local transitionTimer = 0
local resx, resy = game.GetResolution()
local outTimer = 1
local jacket = 0

function render(deltaTime)
    deboxi = 0
    if song.jacket == 0 and jacket == 0 then
        jacket = gfx.LoadImageJob("song_select/loading.png", 0)
    elseif jacket == 0 then
        jacket = song.jacket
    end
    render_screen(transitionTimer, false)
    transitionTimer = transitionTimer + deltaTime * 2
    transitionTimer = math.min(transitionTimer,1)
    return transitionTimer >= 1
end

function render_out(deltaTime)
    deboxi = 0
    outTimer = outTimer + deltaTime * 2
    outTimer = math.min(outTimer, 2)
    render_screen(outTimer, true)
    return outTimer >= 2;
end

function sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

function render_screen(progress, isOut) --new argument: isOut - exactly what it says on the tin
    --jacket vars
    local easeprog, beginx, beginy, beginsize, finalx, finaly, finalsize
    --easeprog only applies to jacket for now (lol there isn't even easing currently)

    if isOut then
        easeprog = progress - 1
        beginx, beginy, beginsize = (resx/2)-150, resy/2+100-150-200, 300 --copied from below
        finalx, finaly, finalsize = 5 * resx / 1280, 5 * resx / 1280, 100 * resx / 1280 -- this is literally the variables for rendering jacket on draw_song_info, but broken down back into resx,resy and math operations and design scale stuff
    else
        easeprog = progress
        beginx, beginy, beginsize = ((((resx/5*2)-((math.floor(resx/5*2/16))*2))/2) - ((math.floor(((resy/5/2*9)-((math.floor(resy/5/2*9/32))*2))/3))/2)) + (math.floor((resx/5*2)/16)), math.floor(resy/5/2*9/32)+math.floor(resy/5/2*9/32), math.floor(((resy/5/2*9)-((math.floor(resy/5/2*9/32))*2))/3) -- this is literally the variables for rendering jacket on sone_selected, but broken down back into resx,resy and math operations
        finalx, finaly, finalsize = (resx/2)-150, resy/2+100-150-200, 300 --replicate original location
    end

    -- do easing here (if those exist)
    -- output it as easeprog

    local nowx, nowy, nowsize = beginx + ((finalx - beginx) * easeprog), beginy + ((finaly - beginy) * easeprog), beginsize + ((finalsize - beginsize) * easeprog) --this is where the movement comes
    --

    --darken the song_selected's or draw_song_info's jackets first
    if isOut then
        gfx.BeginPath()
        gfx.Rect(finalx, finaly, finalsize, finalsize)
        gfx.FillColor(0, 0, 0, 220)
        gfx.Fill()
    else
        gfx.BeginPath()
        gfx.Rect(beginx, beginy, beginsize, beginsize)
        gfx.FillColor(0, 0, 0, 220)
        gfx.Fill()
    end

    for i=0,resx*1.5/50 do --just some cool diagonal lines nothing to see here
        local dir = sign((i % 2) - 0.5)
        local yoff = dir * resy * (1 - progress) - (resy * 0.7)
        gfx.Save()
        gfx.Rotate(math.rad(45))
        gfx.Translate(0,yoff)
        gfx.BeginPath()
        gfx.Rect(60 * i, yoff, 60, resy * 2.5)
        gfx.FillColor(0,64, 150 + 25 * dir)
        gfx.Fill()
        gfx.Restore()
    end
    local y = (resy/2 + 100) * (math.sin(0.5 * progress * math.pi)^7) - 200

    gfx.Save()
    gfx.BeginPath()
    gfx.Translate(nowx, nowy)
    gfx.ImageRect(0,0,nowsize,nowsize,jacket,1,0) --draw the actual jacket
    gfx.Restore()

    gfx.Save()
    gfx.Translate(resx/2, resy - y - 50)
    gfx.FillColor(255,255,255)
    gfx.TextAlign(gfx.TEXT_ALIGN_CENTER + gfx.TEXT_ALIGN_TOP)
    gfx.FontSize(80)
    gfx.Text(song.title,0,0)
    gfx.FontSize(55)
    gfx.Text(song.artist,0,80)
    gfx.Restore()
end
