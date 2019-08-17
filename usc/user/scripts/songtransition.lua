local transitionTimer = 0
local resx, resy = game.GetResolution()
local outTimer = 1
local jacket = 0

function render(deltaTime)
    deboxi = 0
    render_screen(transitionTimer, false)
    transitionTimer = transitionTimer + deltaTime * 2
    transitionTimer = math.min(transitionTimer,1)
    if song.jacket == 0 and jacket == 0 then
        jacket = gfx.CreateSkinImage("song_select/loading.png", 0)
    elseif jacket == 0 then
        jacket = song.jacket
    end
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

function render_screen(progress, isOut)
    --jacket vars

    local rprog, beginx, beginy, beginsize, finalx, finaly, finalsize
    if isOut then
        rprog = progress - 1
        beginx, beginy, beginsize = (resx/2)-150, resy/2+100-150-200, 300
        finalx, finaly, finalsize = 5 * resx / 1280, 5 * resx / 1280, 100 * resx / 1280
    else
        rprog = progress
        beginx, beginy, beginsize = ((((resx/5*2)-((math.floor(resx/5*2/16))*2))/2) - ((math.floor(((resy/5/2*9)-((math.floor(resy/5/2*9/32))*2))/3))/2)) + (math.floor((resx/5*2)/16)), math.floor(resy/5/2*9/32)+math.floor(resy/5/2*9/32), math.floor(((resy/5/2*9)-((math.floor(resy/5/2*9/32))*2))/3)
        finalx, finaly, finalsize = (resx/2)-150, resy/2+100-150-200, 300
    end
    
    local nowx, nowy, nowsize = beginx + ((finalx - beginx) * rprog), beginy + ((finaly - beginy) * rprog), beginsize + ((finalsize - beginsize) * rprog)
    --
    if not isOut then
        gfx.BeginPath()
        gfx.Rect(beginx, beginy, beginsize, beginsize)
        gfx.FillColor(0, 0, 0, 220)
        gfx.Fill()
    end
    
    for i=0,resx*1.5/50 do
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
    do
        gfx.BeginPath()
        gfx.Translate(nowx, nowy)
        gfx.ImageRect(0,0,nowsize,nowsize,jacket,1,0)
        gfx.Restore()
    end

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