function fish_prompt --description 'Write out the prompt'
        set -l last_status $status

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
        echo

        # A full heart while things go well; a failed command costs it
        if test $last_status -eq 0
                set_color e0404f
                echo -n '♥ '
        else
                set_color 8a3a52
                echo -n "♡ $last_status "
        end

        set_color c8df7c
        echo -n '➤ '
        set_color --reset
end
