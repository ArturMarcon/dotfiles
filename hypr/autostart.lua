-----------------------
------ AUTOSTART ------
-----------------------

-- Wallpapers (quickshell/hyrule-wallpaper): the animation on the horizontal monitors,
-- a still on the vertical one. The video is decoded on the Intel iGPU and drawn from
-- GPU memory. Qt probes CUDA, VDPAU and Vulkan when it starts, which would keep the
-- NVIDIA GPU awake, so those are hidden from it
local wallpaper = "QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi CUDA_VISIBLE_DEVICES= VDPAU_DRIVER=none "
  .. "VK_DRIVER_FILES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json "
  .. "__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json "
  .. "qs -p /home/arturmarcon/.config/quickshell/hyrule-wallpaper/shell.qml"

hl.on("hyprland.start", function ()
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("qs -p /home/arturmarcon/.config/quickshell/hyrule-bar/shell.qml")
  hl.exec_cmd(wallpaper)
end)
