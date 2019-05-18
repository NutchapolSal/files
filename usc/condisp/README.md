# Nutchapol's CONtroller DISPlay

###### ConDisp

For [USC](https://github.com/Drewol/unnamed-sdvx-clone)

v3: **Table-based knob speed** no more `ls1` `ls2` `ls3` etc stuff!

did not made this with both portrait/landscape compactibility, only for landscape so lol (but you have your flashy 3d console with portrait anyways)

![gifpreview](https://github.com/NutchapolSal/files/raw/master/usc/condisp/prev.gif)

[See it in action (v2)](https://youtu.be/k5bmK1dlRK4)

also thanks usc discord for pushing me into making knobs support

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

`gfx.Translate` is like this photoshop thing

![translate](https://github.com/NutchapolSal/files/raw/master/usc/condisp/translate.png)

where you drag it out and it just changes the 0, 0 position to where you dropped it (although this is ~~more like~~ "move 0, 0 x units right and y units down")

`gfx.Rotate` rotates around the current 0, 0

`gfx.Save` & `gfx.Restore` is for saving & restoring transformations(translate, rotate, skew, etc). yes there are default transformations going into the function so don't forget to save & restore those when you use transformations or you might fk up everything executing after

#### specifics

change `posx` and `posy` to move it

4 default "fly in" intro animations for use or make one yourself

anchor location(`posx` & `posy` position):

![anchor location](https://github.com/NutchapolSal/files/raw/master/usc/condisp/anchorlocation.png)

button sizes are based off actual button sizes, use the [`xlsx`](https://github.com/NutchapolSal/files/raw/master/usc/condisp/design.xlsx) and [`psd`](https://github.com/NutchapolSal/files/raw/master/usc/condisp/design.psd) files to help locating rectangle locations & sizes

`gfx.drawRectBool` function is just the `gfx.drawRect` function but uses booleans to determine if to do stroke/fill

same with `gfx.drawCircleBool` (lol `gfx.drawCircle` doesnt even exist)