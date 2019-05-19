# Nutchapol's LiveForce

For [USC](https://github.com/Drewol/unnamed-sdvx-clone)

Shows your force for current play

![gifpreview](https://github.com/NutchapolSal/files/raw/master/usc/liveforce/prev.gif)

<!-- [See it in action](https://youtu.be/k5bmK1dlRK4) -->

### How to install
1. Go to your skin folder, inside `scripts`
2. Open `gameplay.lua` with notepad or something
3. Copy contents of [`liveforce.lua`](https://raw.githubusercontent.com/NutchapolSal/files/master/usc/liveforce/liveforce.lua) and place it at the bottom
4. Find `function render`
5. Type in `draw_liveforce()` under `draw_alerts(deltaTime)`

### notice

no intro animations bc i'm lazy

make one or try copying from [condisp](https://github.com/NutchapolSal/files/tree/master/usc/condisp) or something lol

### about force and this thing

read about force [here](http://bemaniwiki.com/index.php?SOUND%20VOLTEX%20VIVID%20WAVE/VOLFORCE) (if you don't read japanese then translate the page to english)

![describing](https://github.com/NutchapolSal/files/raw/master/usc/liveforce/describe.png)

red box: current clear badge (puc, uc, hard clear, clear, failed(yes, you can see your force for failed plays when the screen dims))

yellow box: current grade (d to s)

green box: current force

blue box: max possible force for this play, calculated from the current clear badge and assumes you will get an s.

purple box: volforce class that this play reaches

this will render the grade & clear badges proportionally resized instead of squished into a square if you replaced them. they might intersect if they are too long