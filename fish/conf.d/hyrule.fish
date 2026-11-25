# Hyrule forest theme for fish: live syntax colors, the completion menu,
# fzf popups, and a notice when a long command finishes in the background.
status is-interactive; or return

# Syntax highlighting while typing: real commands glow lime, unknown ones turn red
set -g fish_color_normal dfe8c4
set -g fish_color_command c8df7c
set -g fish_color_keyword 7cc8b4
set -g fish_color_param c9d4b4
set -g fish_color_option a9c08a
set -g fish_color_quote e6ad5c
set -g fish_color_escape f2cf86
set -g fish_color_operator e6ad5c
set -g fish_color_redirection a3e0cf
set -g fish_color_end 669b62
set -g fish_color_error ff7a7f
set -g fish_color_comment 5f7d55 --italics
set -g fish_color_autosuggestion 5f7d55
set -g fish_color_valid_path --underline
set -g fish_color_selection --background=29543d
set -g fish_color_search_match --background=35694c
set -g fish_color_history_current --bold
set -g fish_color_cancel e0404f
set -g fish_color_cwd 9aca68
set -g fish_color_user c8df7c
set -g fish_color_host 9aca68
set -g fish_color_host_remote e6ad5c

# Tab-completion menu
set -g fish_pager_color_prefix c8df7c --bold --underline
set -g fish_pager_color_completion dfe8c4
set -g fish_pager_color_description 669b62 --italics
set -g fish_pager_color_progress 0a1f1b --background=9aca68
set -g fish_pager_color_selected_background --background=35694c
set -g fish_pager_color_selected_prefix eef3c4 --bold --underline
set -g fish_pager_color_selected_completion eef3c4 --bold
set -g fish_pager_color_selected_description c8df7c

# Once a command runs, its prompt collapses to the heart line (see fish_prompt)
set -g fish_transient_prompt 1

# fzf popups: Ctrl+R history, Ctrl+T folders, Alt+C files (active once fzf is installed)
set -gx FZF_DEFAULT_OPTS "--layout=reverse --height=50% --border=rounded --info=inline-right \
--prompt='◆ ' --pointer='➤' --marker='♥' --separator='─' --scrollbar='▏' \
--color=fg:#c9d4b4,fg+:#eef3d6,bg:-1,bg+:#1e4a38,gutter:-1,hl:#c8df7c,hl+:#c8df7c \
--color=border:#35694c,separator:#29543d,scrollbar:#35694c,label:#e6ad5c,query:#eef3d6 \
--color=prompt:#e6ad5c,pointer:#c8df7c,marker:#e0404f,spinner:#7cc8b4,info:#669b62,header:#7cc8b4"
if type -q fd
    set -gx FZF_CTRL_T_COMMAND "fd --type f --hidden --follow --exclude .git"
    set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --exclude .git"
end
if type -q bat
    # bat's "ansi" theme uses the terminal's own (forest) colors
    set -gx BAT_THEME ansi
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
end
if type -q fzf
    fzf --fish | source
    # Swapped from fzf's defaults: Ctrl+T jumps to a folder, Alt+C picks files
    for mode in default insert
        bind -M $mode ctrl-t fzf-cd-widget
        bind -M $mode alt-c fzf-file-widget
    end
end

# A command that ran 30s+ sends a desktop notification if you looked away
function __hyrule_notify_long_command --on-event fish_postexec
    set -l last_status $status
    test "$CMD_DURATION" -ge 30000; or return

    # Still looking at this terminal: no need to notify
    if set -q KITTY_PID
        set -l focused (hyprctl activewindow -j 2>/dev/null | string match -rg '"pid": (\d+)')
        test "$focused" = "$KITTY_PID"; and return
    end

    set -l cmd (string shorten -m 60 -- $argv[1])
    set -l took (__hyrule_duration $CMD_DURATION)
    if test $last_status -eq 0
        notify-send -a Hyrule -i utilities-terminal "Quest complete" "$cmd · took $took"
    else
        notify-send -a Hyrule -i dialog-error "Quest failed ♡ $last_status" "$cmd · took $took"
    end
end
