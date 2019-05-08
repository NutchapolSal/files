# Nutchapol's CONtroller DISPlay

###### ConDisp

For [USC](https://github.com/Drewol/unnamed-sdvx-clone)

no knobs because the game can't

did not made this with both portrait/landscape compactibility, only for landscape so lol

![gifpreview](https://github.com/NutchapolSal/files/raw/master/usc/condisp/prev.gif)

[See it in action](https://youtu.be/8vpFTbocm_k)

### [NOV] How to install
1. Go to your skin folder, inside `scripts`
2. Open `gameplay.lua` with notepad or something
3. Copy contents of [`condisp.lua`](https://raw.githubusercontent.com/NutchapolSal/files/master/usc/condisp/condisp.lua) and place it at the bottom
4. Find `function render`
5. Type in `draw_condisp()` under `draw_alerts(deltaTime)`
6. (optional) Customize ConDisp to your liking

### [EXH] How to install

put contents of [`condisp.lua`](https://raw.githubusercontent.com/NutchapolSal/files/master/usc/condisp/condisp.lua) inside `gameplay.lua`

put `draw_condisp()` somewhere in the render function

change some values if you want

### Info for those who wants to customize it

#### common usc skinner knowledge

things are based in "design size" which is 1280x720(720x1280 for portrait i think), then resized to fit your monitor (that's why the psd is 1280x720 even though my resolution is 1920x1080)

`gfx.FillColor` & `gfx.StrokeColor` is like setting the fill color & stroke color and then you use the rectangle tool to draw many rectangles with those specified colors

#### specifics

change `origx` and `origy` to move it

4 default "fly in" intro animations for use or make one yourself

anchor location(`origx` & `origy` position):

![anchor location](https://github.com/NutchapolSal/files/raw/master/usc/condisp/anchorlocation.png)

button sizes are based off actual button sizes, use the [`xlsx`](https://github.com/NutchapolSal/files/raw/master/usc/condisp/design.xlsx) and [`psd`](https://github.com/NutchapolSal/files/raw/master/usc/condisp/design.psd) files to help locating rectangle locations & sizes

`drawRectBool` function is just the `drawRect` function but uses booleans to determine if to do stroke/fill