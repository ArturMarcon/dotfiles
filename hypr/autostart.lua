-----------------------
------ AUTOSTART ------
-----------------------

hl.on("hyprland.start", function ()
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("qs -p /home/arturmarcon/.config/quickshell/frieren-bar/shell.qml")
end)
