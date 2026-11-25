function fish_prompt --description 'Write out the prompt'
        set -l last_status $status

        # Once a command runs (fish_transient_prompt), its prompt collapses to the heart line
        set -l final (contains -- --final-rendering $argv; and echo 1)

        if test -z "$final"
                set_color 7cc8b4
                echo -n '◆ '
                set_color --bold c8df7c
                echo -n $USER
                set_color --reset
                set_color 669b62
                echo -n '@'
                set_color 9aca68
                echo -n (prompt_hostname)

                set_color 669b62
                echo -n ':'

                # Stamina spent: how long the last command took, when it was a while
                if test "$CMD_DURATION" -ge 3000
                        set_color e6ad5c
                        echo -n ' ◔ '(__hyrule_duration $CMD_DURATION)
                end
                echo
        end

        # A full heart while things go well; a failed command costs it
        if test $last_status -eq 0
                set_color e0404f
                echo -n '♥ '
        else
                set_color 8a3a52
                echo -n "♡ $last_status "
        end

        # Past prompts fade back so the live one stands out
        if test -n "$final"
                set_color 669b62
        else
                set_color c8df7c
        end
        echo -n '➤ '
        set_color --reset
end
