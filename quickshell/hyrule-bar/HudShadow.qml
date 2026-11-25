import QtQuick
import QtQuick.Effects

// Soft drop shadow that keeps the floating HUD readable over any wallpaper.
MultiEffect {
    shadowEnabled: true
    shadowColor: Theme.hudShadow
    shadowBlur: 0.5
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 1
}
