
```~/.config/fish/config.fish
function source_project_env --on-event fish_prompt
    # only run once per shell
    if set -q __env_already_sourced
        return
    end

    set dir (pwd)
    while test "$dir" != "/"
        if test -f "$dir/dev-tools/config/bin-setup-env/setup.fish"
            source "$dir/dev-tools/config/bin-setup-env/setup.fish"
            set -g __env_already_sourced 1
            echo "[✔] Coding Agent loaded from: $dir/dev-tools/config/bin-setup-env/setup.fish"
            return
        end
        set dir (dirname "$dir")
    end
end
```
