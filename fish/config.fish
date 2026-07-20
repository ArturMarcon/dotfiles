if status is-interactive
	## Vertical list replacement for ls
	alias ls="exa -1a --icons --color=always --group-directories-first"

	# Detailed list view
	alias ll="exa -lah --icons --color=always --group-directories-first --git --header"

	# Tree view
	alias lt="exa -a --tree --level=2 --icons --color=always --group-directories-first"
end
