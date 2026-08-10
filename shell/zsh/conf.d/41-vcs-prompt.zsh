# Git branch/status in the right-hand prompt, computed asynchronously.
#
# Adapted from https://github.com/vincentbernat/zshrc
#
# Numbered 41 rather than 21 (next to the prompt) because it depends on
# zsh-async being loaded by 40-plugins.zsh. check-for-changes runs a full
# `git status`, which is slow in large repositories -- hence the worker.

# Skipped for root, which has no business running git in someone's tree.
if [[ $EUID -ne 0 ]] && (( $+functions[async_start_worker] )); then

    autoload -Uz vcs_info add-zsh-hook

    _vcs_async_start() {
        async_start_worker vcs_info 2>/dev/null
        async_register_callback vcs_info _vcs_info_done
    }

    _vcs_info_compute() {
        cd $1
        vcs_info
        print ${vcs_info_msg_0_}
    }

    _vcs_info_done() {
        local job=$1 return_code=$2 stdout=$3 more=$6

        # The worker died (suspend/resume, or a killed process group).
        # Restart it rather than silently losing the RPROMPT.
        if [[ $job == '[async]' ]]; then
            (( return_code != 0 )) && { _vcs_async_start; return }
        fi

        vcs_info_msg_0_=$stdout
        [[ $more == 1 ]] || zle && { zle reset-prompt; zle -R }
    }

    RPROMPT='$vcs_info_msg_0_'

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*:*' formats       "%F{yellow}%b%c%u%f"
    zstyle ':vcs_info:*:*' actionformats "%F{yellow}%b|%a%c%u%f"
    zstyle ':vcs_info:*:*' check-for-changes true
    zstyle ':vcs_info:*:*' stagedstr   "+"
    zstyle ':vcs_info:*:*' unstagedstr "*"
    zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

    # Treat untracked files as unstaged, showing a single * for either.
    +vi-git-untracked() {
        [[ -n ${hook_com[unstaged]} ]] && return
        if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]] && \
           git status --porcelain 2>/dev/null | grep -q '??'; then
            hook_com[unstaged]+="*"
        fi
    }

    _vcs_async_start
    add-zsh-hook precmd () { async_job vcs_info _vcs_info_compute $PWD }
    add-zsh-hook chpwd () { vcs_info_msg_0_= }
fi
