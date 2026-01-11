# Git worktree manager with fzf
#
# Inspired by: https://github.com/hiroppy/dotfiles/blob/master/config/fish/functions/wt.fish
# Article: https://hiroppy.me/blog/posts/git-worktree-fish
#
# Features:
# - fzf preview with branch info, changed files, and recent commits
# - `gw`: select and switch to a worktree
# - `gw add [branch]`: create worktree (with branch selector if no argument)
# - `gw remove [target]`: remove worktree (with selector if no argument)
# - Worktrees stored in .git/worktrees-gw/

function gw --description "Git worktree manager with fzf"
    # Check if we're in a git repository
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "Error: Not in a git repository"
        return 1
    end

    set -l git_dir (git rev-parse --git-dir)
    set -l worktrees_dir "$git_dir/worktrees-gw"

    # Handle subcommands
    set -l cmd $argv[1]

    if test "$cmd" = "remove"
        # Remove worktree
        set -l target $argv[2]

        if test -z "$target"
            # No argument - show fzf to select worktree to remove
            __gw_remove_interactive "$worktrees_dir"
            return
        end

        # Try to find worktree by:
        # 1. Exact branch name match
        # 2. Directory name match (for branches with / replaced by -)
        # 3. Direct path match

        set -l worktree_path ""

        # Method 1: Find by branch name
        set -l worktree_info (git worktree list | grep "\[$target\]")
        if test -n "$worktree_info"
            set worktree_path (echo $worktree_info | awk '{print $1}')
        end

        # Method 2: Find by directory name in worktrees-gw
        if test -z "$worktree_path" -a -d "$worktrees_dir/$target"
            set worktree_path "$worktrees_dir/$target"
        end

        # Method 3: Check if it's a direct path
        if test -z "$worktree_path" -a -d "$target"
            set worktree_path "$target"
        end

        if test -z "$worktree_path"
            echo "No worktree found for: $target"
            echo "Try 'gw remove' without arguments to select interactively."
            return 1
        end

        # Confirm removal
        echo "Removing worktree at: $worktree_path"
        git worktree remove --force "$worktree_path"

        if test $status -eq 0
            echo "Worktree removed successfully"
        end
        return

    else if test "$cmd" = "add"
        # gw add <branch> - Create worktree for specified branch
        set -l branch_name $argv[2]

        if test -z "$branch_name"
            # No branch specified - show branch selector
            __gw_select_branch_and_create "$worktrees_dir"
        else
            __gw_create_worktree "$branch_name" "$worktrees_dir"
        end
        return

    else if test -n "$cmd"
        echo "Unknown command: $cmd"
        echo "Usage:"
        echo "  gw              - Select worktree with fzf"
        echo "  gw add <branch> - Create worktree for branch"
        echo "  gw remove [branch|dir] - Remove worktree"
        return 1
    end

    # gw (no arguments) - Interactive worktree selection
    set -l worktree_list (git worktree list --porcelain | string match -r '^worktree .*' | string replace 'worktree ' '')

    # Skip the main worktree (first one) for selection
    set -l main_worktree (git rev-parse --show-toplevel)

    # Build list for fzf: "path [branch]"
    set -l fzf_input
    for wt_path in $worktree_list
        if test "$wt_path" != "$main_worktree"
            set -l branch (git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
            set -a fzf_input "$wt_path [$branch]"
        end
    end

    if test (count $fzf_input) -eq 0
        # No worktrees exist, go directly to branch selection
        echo "No worktrees found. Select a branch to create one:"
        __gw_select_branch_and_create "$worktrees_dir"
        return
    end

    # Show worktree list with fzf
    set -l preview_script 'sh -c '\''
        worktree_path=$(echo "$1" | awk "{print \$1}")
        branch=$(echo "$1" | sed "s/.*\\[//" | sed "s/\\]//")

        echo "┌──────────────────────────────────────────────────┐"
        echo "│ 🌳 Branch: $branch"
        echo "└──────────────────────────────────────────────────┘"
        echo ""
        echo "📁 Path: $worktree_path"
        echo ""
        echo "📝 Changed files:"
        echo "───────────────────────────────────────────────────"
        changes=$(git -C "$worktree_path" status --porcelain 2>/dev/null)
        if [ -z "$changes" ]; then
            echo "  ✨ Working tree clean"
        else
            echo "$changes" | head -10 | while read line; do
                file_status=$(echo "$line" | cut -c1-2)
                file_name=$(echo "$line" | cut -c4-)
                case "$file_status" in
                    "M "*) echo "  🔧 Modified: $file_name";;
                    "A "*) echo "  ➕ Added: $file_name";;
                    "D "*) echo "  ➖ Deleted: $file_name";;
                    "??"*) echo "  ❓ Untracked: $file_name";;
                    *) echo "  📄 $line";;
                esac
            done
        fi
        echo ""
        echo "📜 Recent commits:"
        echo "───────────────────────────────────────────────────"
        git -C "$worktree_path" log --oneline --color=always -10 2>/dev/null | sed "s/^/  /"
    '\'' _ {}'

    set -l selected (printf '%s\n' $fzf_input | fzf \
        --preview="$preview_script" \
        --preview-window="right:60%:wrap" \
        --header="Git Worktrees | Enter: switch | No match + Enter: create new" \
        --border \
        --height=80% \
        --layout=reverse \
        --print-query \
        --expect=enter)

    # Parse fzf output
    # Line 1: query, Line 2: key pressed, Line 3: selected item
    set -l query $selected[1]
    set -l key $selected[2]
    set -l selection $selected[3]

    if test -n "$selection"
        # User selected an existing worktree
        set -l target_path (echo $selection | awk '{print $1}')
        cd "$target_path"
        echo "Switched to: $target_path"
    else if test "$key" = "enter" -a -n "$query"
        # No match, user pressed enter with a query - try to create worktree
        # Check if query matches a branch name
        if git show-ref --verify --quiet "refs/heads/$query" 2>/dev/null; or git show-ref --verify --quiet "refs/remotes/origin/$query" 2>/dev/null
            __gw_create_worktree "$query" "$worktrees_dir"
        else
            # Show branch selector
            echo "Branch '$query' not found. Select from available branches:"
            __gw_select_branch_and_create "$worktrees_dir" "$query"
        end
    else if test "$key" = "enter"
        # Enter pressed with empty query and no selection - show branch list
        __gw_select_branch_and_create "$worktrees_dir"
    end
end

function __gw_create_worktree --description "Create a worktree for a branch"
    set -l branch_name $argv[1]
    set -l worktrees_dir $argv[2]

    if test -z "$branch_name"
        echo "Error: Branch name required"
        return 1
    end

    # Ensure worktrees directory exists
    if not test -d "$worktrees_dir"
        mkdir -p "$worktrees_dir"
    end

    # Sanitize branch name for directory (replace / with -)
    set -l dir_name (string replace -a '/' '-' "$branch_name")
    set -l worktree_path "$worktrees_dir/$dir_name"

    # Check if worktree already exists
    if test -d "$worktree_path"
        echo "Worktree already exists at: $worktree_path"
        cd "$worktree_path"
        return 0
    end

    # Check if branch exists locally
    if git show-ref --verify --quiet "refs/heads/$branch_name" 2>/dev/null
        # Local branch exists
        git worktree add "$worktree_path" "$branch_name"
    else if git show-ref --verify --quiet "refs/remotes/origin/$branch_name" 2>/dev/null
        # Remote branch exists, create tracking branch
        git worktree add "$worktree_path" -b "$branch_name" "origin/$branch_name"
    else
        # Branch doesn't exist, create new branch from current HEAD
        echo "Branch '$branch_name' does not exist. Creating new branch from HEAD."
        git worktree add -b "$branch_name" "$worktree_path"
    end

    if test $status -eq 0
        echo "Created worktree at: $worktree_path"
        cd "$worktree_path"
    else
        echo "Failed to create worktree"
        return 1
    end
end

function __gw_select_branch_and_create --description "Show branch selector and create worktree"
    set -l worktrees_dir $argv[1]
    set -l initial_query $argv[2]

    # Special item for creating new branch
    set -l new_branch_marker "+ Create new branch..."

    # Get all branches (local and remote)
    set -l branches (git branch -a --format='%(refname:short)' | grep -v 'HEAD' | sed 's|^origin/||' | sort -u)

    set -l preview_script 'sh -c '\''
        item="$1"
        if echo "$item" | grep -q "^+ Create new branch"; then
            echo "┌──────────────────────────────────────────────────┐"
            echo "│ ✨ Create NEW branch"
            echo "└──────────────────────────────────────────────────┘"
            echo ""
            echo "Select this option to enter a new branch name."
            echo "The new branch will be created from the current HEAD."
        else
            branch=$(echo "$item" | sed "s|^origin/||")
            echo "┌──────────────────────────────────────────────────┐"
            echo "│ 🌳 Branch: $branch"
            echo "└──────────────────────────────────────────────────┘"
            echo ""
            echo "📜 Recent commits:"
            echo "───────────────────────────────────────────────────"
            git log --oneline --color=always -10 "$branch" 2>/dev/null || git log --oneline --color=always -10 "origin/$branch" 2>/dev/null | sed "s/^/  /"
        fi
    '\'' _ {}'

    set -l fzf_args \
        --preview="$preview_script" \
        --preview-window="right:60%:wrap" \
        --header="Select existing branch or create new" \
        --border \
        --height=80% \
        --layout=reverse

    if test -n "$initial_query"
        set -a fzf_args --query="$initial_query"
    end

    # Put the new branch marker at the top
    set -l selection (printf '%s\n' $new_branch_marker $branches | fzf $fzf_args)

    if test -z "$selection"
        # No selection, cancelled
        return
    end

    if test "$selection" = "$new_branch_marker"
        # User selected the "create new branch" option - prompt for name
        read -P "Enter new branch name: " -l new_branch_name
        if test -z "$new_branch_name"
            echo "Cancelled: no branch name entered"
            return 1
        end
        __gw_create_worktree "$new_branch_name" "$worktrees_dir"
    else
        # User selected an existing branch
        __gw_create_worktree "$selection" "$worktrees_dir"
    end
end

function __gw_remove_interactive --description "Show fzf to select worktree to remove"
    set -l worktrees_dir $argv[1]

    # Get worktree list excluding main
    set -l worktree_list (git worktree list --porcelain | string match -r '^worktree .*' | string replace 'worktree ' '')
    set -l main_worktree (git rev-parse --show-toplevel)

    set -l fzf_input
    for wt_path in $worktree_list
        if test "$wt_path" != "$main_worktree"
            set -l branch (git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
            set -a fzf_input "$wt_path [$branch]"
        end
    end

    if test (count $fzf_input) -eq 0
        echo "No worktrees to remove"
        return 1
    end

    set -l preview_script 'sh -c '\''
        worktree_path=$(echo "$1" | awk "{print \$1}")
        branch=$(echo "$1" | sed "s/.*\\[//" | sed "s/\\]//")

        echo "┌──────────────────────────────────────────────────┐"
        echo "│ 🌳 Branch: $branch"
        echo "└──────────────────────────────────────────────────┘"
        echo ""
        echo "📁 Path: $worktree_path"
        echo ""
        echo "📝 Changed files:"
        echo "───────────────────────────────────────────────────"
        changes=$(git -C "$worktree_path" status --porcelain 2>/dev/null)
        if [ -z "$changes" ]; then
            echo "  ✨ Working tree clean"
        else
            echo "$changes" | head -10 | while read line; do
                file_status=$(echo "$line" | cut -c1-2)
                file_name=$(echo "$line" | cut -c4-)
                case "$file_status" in
                    "M "*) echo "  🔧 Modified: $file_name";;
                    "A "*) echo "  ➕ Added: $file_name";;
                    "D "*) echo "  ➖ Deleted: $file_name";;
                    "??"*) echo "  ❓ Untracked: $file_name";;
                    *) echo "  📄 $line";;
                esac
            done
        fi
        echo ""
        echo "📜 Recent commits:"
        echo "───────────────────────────────────────────────────"
        git -C "$worktree_path" log --oneline --color=always -10 2>/dev/null | sed "s/^/  /"
    '\'' _ {}'

    set -l selected (printf '%s\n' $fzf_input | fzf \
        --preview="$preview_script" \
        --preview-window="right:60%:wrap" \
        --header="Select worktree to REMOVE (Enter to confirm)" \
        --border \
        --height=80% \
        --layout=reverse)

    if test -n "$selected"
        set -l worktree_path (echo $selected | awk '{print $1}')
        echo "Removing worktree at: $worktree_path"
        git worktree remove --force "$worktree_path"

        if test $status -eq 0
            echo "Worktree removed successfully"
        end
    end
end
