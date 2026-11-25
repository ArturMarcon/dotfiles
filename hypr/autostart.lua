-----------------------
------ AUTOSTART ------
-----------------------

-- Wallpapers: animation on the two horizontal monitors (decoded on the Intel iGPU),
-- still image on the vertical one
local wallpapers = "/home/arturmarcon/wallpapers/"
local animation = wallpapers .. "link-and-the-forest-temple-botw-moewalls-com.mp4"
local vertical = wallpapers .. "botw-vertical.jpg"
local gslapper = "GST_PLUGIN_FEATURE_RANK=vah264dec:MAX,nvh264dec:NONE gslapper -p -o \"no-audio loop\" "

hl.on("hyprland.start", function ()
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("qs -p /home/arturmarcon/.config/quickshell/hyrule-bar/shell.qml")
  hl.exec_cmd(gslapper .. "eDP-1 " .. animation)
  hl.exec_cmd(gslapper .. "DP-2 " .. animation)
  hl.exec_cmd("gslapper -o fill DP-3 " .. vertical)
end)
