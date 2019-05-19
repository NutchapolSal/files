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
    local force, maxForce, replayForce = 0, 0, 0 --force stuffs
    local badgeSize, gradeSize, gradew, gradeh, badgew, badgeh --graphic stuffs
    local prefix, diff --force diff stuffs
    local mainx, mainy, mainw, mainh, subx, suby, subw, subh, maxx, maxy, maxx2, maxy2, clsx, clsy, clsx2, clsy2 -- text bounds
    local class, clv, cr, cg, cb --volforce class stuffs

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

    gfx.Translate(13, 455)

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

    debox(maxy2)

    gfx.Restore()
end
-- -------------------------------------------------------------------------- --