import QtQuick
import Quickshell

// Entry point for the Inventory file manager. It runs as its own Quickshell
// instance, apart from the bar, so neither can take the other down.
// scripts/inventory-open.sh starts it on first use.
ShellRoot {
    InventoryWindow {
    }
}
