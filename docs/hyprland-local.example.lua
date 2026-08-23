-- Example machine-local Hyprland hardware configuration for the current host.
-- Copy this file to ~/.config/hypr/hyprland.local.lua and adjust it there.
-- Chezmoi intentionally does not manage the destination file.

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "preferred",
    position = "0x2160",
    scale    = 1,
})

hl.monitor({
    output   = "HDMI-A-2",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.device({
    name           = "logitech-g602-1",
    natural_scroll = true,
})

hl.device({
    name           = "logitech-wireless-mouse-pid:402c-1",
    natural_scroll = true,
})

local swapMonitorWorkspaces = hl.dsp.workspace.swap_monitors({
    monitor1 = "HDMI-A-1",
    monitor2 = "HDMI-A-2",
})
hl.bind("SUPER + SHIFT + PERIOD", swapMonitorWorkspaces)
hl.bind("SUPER + SHIFT + COMMA", swapMonitorWorkspaces)
