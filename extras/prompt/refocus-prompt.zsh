# Source this in ~/.zshrc:
#   source /full/path/to/extras/prompt/refocus-prompt.zsh
_refocus_precmd() {
  local dir="${REFOCUS_STATE_DIR:-$HOME/.local/refocus}"
  local verfile="$dir/prompt.ver" cache="$dir/prompt.cache"
  typeset -g REFOCUS_LAST_VER; [[ -z "$REFOCUS_LAST_VER" ]] && REFOCUS_LAST_VER=0
  local ver=0; [[ -r "$verfile" ]] && ver=$(<"$verfile")
  if [[ "$ver" != "$REFOCUS_LAST_VER" ]]; then
    REFOCUS_LAST_VER="$ver"
    local seg=""
    if [[ -r "$cache" ]]; then
      IFS='|' read -r st proj mins <"$cache"
      if [[ "$st" == "on" ]]; then
        [[ -z "$proj" || "$proj" == "-" ]] && proj="(no project)"
        [[ -z "$mins" || "$mins" == "-" ]] && mins="0"
        seg=" ⏳ ${proj} (${mins}m)"
      fi
    fi
    typeset -g REFOCUS_PROMPT_SEG="$seg"
  fi
}
precmd_functions+=(_refocus_precmd)
# Example theme:
# PROMPT='%n@%m %~${REFOCUS_PROMPT_SEG} %# '