# Interactive shell setup
if status is-interactive
    # Commands to run in interactive sessions can go here
    set -gx EDITOR vim

    # Starship
    if command -v starship >/dev/null 2>&1
        starship init fish | source
    end

    # Customize to your needs...

    ### ghq
    function gl
        # FZF_PREVIEW="ls -laTp {} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'"
        set FZF_PREVIEW "cat {}/README.*"  # TODO: Replace cat with bat
        set REPOPATH (ghq list --full-path | fzf --layout=reverse --preview $FZF_PREVIEW)
        if test -n "$REPOPATH"
            cd $REPOPATH
        end
    end

    ### Rosetta
    alias intelzsh='arch -x86_64 zsh'
end

# pnpm
set -gx PNPM_HOME "/Users/whitphx/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# nvm
set --universal nvm_default_version v22.16.0
# nvm end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

set --export PATH "$HOME/.antigravity/antigravity/bin" $PATH

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/whitphx/src/google-cloud-sdk/path.fish.inc' ]; . '/Users/whitphx/src/google-cloud-sdk/path.fish.inc'; end

source ~/.safe-chain/scripts/init-fish.fish # Safe-chain Fish initialization script
