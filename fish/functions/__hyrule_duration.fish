function __hyrule_duration --argument-names ms --description 'Format milliseconds as 4.2s, 3m 05s or 1h 02m'
        set -l s (math -s0 "floor($ms / 1000)")
        if test $s -ge 3600
                printf '%dh %02dm' (math -s0 "floor($s / 3600)") (math -s0 "floor($s % 3600 / 60)")
        else if test $s -ge 60
                printf '%dm %02ds' (math -s0 "floor($s / 60)") (math -s0 "$s % 60")
        else
                printf '%ss' (math -s1 "$ms / 1000")
        end
end
