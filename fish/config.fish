if status is-interactive
	## Grid listing replacement for ls
	alias ls="exa -a --icons --color=always --group-directories-first"

	# Detailed list view
	alias ll="exa -lah --icons --color=always --group-directories-first --git --header"

	# Tree view
	alias lt="exa -a --tree --level=2 --icons --color=always --group-directories-first"
end
