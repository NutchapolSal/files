gfx.LoadSkinFont("NotoSans-Regular.ttf");

deboxi = 0
deboxr = 255
deboxg = 255
deboxb = 255

globalTimer  = 0

dc = function(r, g, b)
    deboxr = math.floor(r or 255)
    deboxg = math.floor(g or 255)
    deboxb = math.floor(b or 255)
end

debox = function(text)
    gfx.Save()
    gfx.ResetTransform()
    gfx.Scale(1.5, 1.5)
    gfx.BeginPath()
    gfx.FontSize(12)
    gfx.TextAlign(gfx.TEXT_ALIGN_LEFT, gfx.TEXT_ALIGN_BOTTOM)
    gfx.FillColor(deboxr, deboxg, deboxb, 255)
    gfx.Text(tostring(text), 0, 200 + (14 * deboxi))
    dc(255, 255, 255)
    deboxi = deboxi + 1
    gfx.Restore()
end