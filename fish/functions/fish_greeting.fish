function fish_greeting --description 'Animated Hyrule greeting, once per login'
        # The marker lives in the runtime dir, which is cleared on logout/reboot
        set -l marker $XDG_RUNTIME_DIR/hyrule-greeted
        test -e $marker; and return
        touch $marker

        set -l lines \
                "The wilds are calm today." \
                "A fair wind blows across the plateau." \
                "Your stamina is full." \
                "The shrines hum softly in the distance." \
                "Somewhere nearby, a Korok is hiding." \
                "The campfire is still warm."
        set -l text (printf '◆ Hyrule awaits, Artur.\n  %s' (random choice $lines) | string collect)

        if type -q tte
                # Light beams sweep in like sun through the canopy, then settle lime to teal
                printf '%s' $text | tte --canvas-width 0 --canvas-height 0 --anchor-canvas nw --frame-rate 60 \
                        beams --beam-delay 1 --beam-row-speed-range 60-120 --beam-column-speed-range 20-30 \
                        --beam-gradient-stops eef3c4 c8df7c 7cc8b4 --beam-gradient-frames 2 \
                        --final-gradient-stops c8df7c 9aca68 7cc8b4 --final-gradient-direction horizontal \
                        --final-gradient-frames 1 --final-gradient-steps 6 --final-wipe-speed 6
        else
                set_color c8df7c
                printf '%s\n' $text
                set_color --reset
        end
        echo
end
