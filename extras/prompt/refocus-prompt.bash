# Source this in ~/.bashrc:
#   source /full/path/to/extras/prompt/refocus-prompt.bash
_refocus_prompt() {
  local dir="${REFOCUS_STATE_DIR:-$HOME/.local/refocus}"
  local verfile="$dir/prompt.ver" cache="$dir/prompt.cache"
  [[ -z "${__REFOCUS_LAST_VER:-}" ]] && __REFOCUS_LAST_VER=0
  local ver=0; [[ -r "$verfile" ]] && ver=$(<"$verfile")
  if [[ "$ver" != "$__REFOCUS_LAST_VER" ]]; then
    __REFOCUS_LAST_VER="$ver"
    __REFOCUS_PROMPT_SEG=""
    if [[ -r "$cache" ]]; then
      IFS='|' read -r st proj mins <"$cache" || true
      if [[ "$st" == "on" ]]; then
        [[ -z "$proj" || "$proj" == "-" ]] && proj="(no project)"
        [[ -z "$mins" || "$mins" == "-" ]] && mins="0"
        __REFOCUS_PROMPT_SEG=" ⏳ ${proj} (${mins}m)"
      fi
    fi
  fi
  PS1="${PS1%\\$ }${__REFOCUS_PROMPT_SEG}\$ "
}
case ":$PROMPT_COMMAND:" in *:_refocus_prompt:*) ;; *) PROMPT_COMMAND="_refocus_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}";; esac