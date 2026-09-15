source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

if status is-interactive
    zoxide init fish --cmd cd | source
end

oh-my-posh init fish --config ~/custom.omp.json | source
