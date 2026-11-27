# Open a folder in the Inventory, the Quickshell file manager:
#   inv .            this folder
#   inv ~/Downloads  any folder (or a file, to see it selected)
#   inv proj         a tab by name or its start, when no such folder is here
#   inv              your home folder, like Super+E
function inv --description 'Open a folder in the Inventory'
    ~/.config/quickshell/hyrule-bar/scripts/inventory-open.sh $argv
end
