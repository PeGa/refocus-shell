# Source this from ~/.bashrc:  source /path/to/extras/prompt/refocus-prompt.bash
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
        
        # Compute live minutes if start.ts exists
        local startfile="$dir/start.ts"
        if [[ -r "$startfile" ]]; then
          local start_ts=$(<"$startfile")
          local now_ts=$(date +%s)
          local live_mins=$(((now_ts - start_ts) / 60))
          __REFOCUS_PROMPT_SEG=" ⏳ ${proj} (${live_mins}m)"
        else
          __REFOCUS_PROMPT_SEG=" ⏳ ${proj} (${mins}m)"
        fi
      fi
    fi
  fi
  PS1="${PS1%\\$ }${__REFOCUS_PROMPT_SEG}\$ "
}
case ":${PROMPT_COMMAND:-}:" in *:_refocus_prompt:*) ;; *) PROMPT_COMMAND="_refocus_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}";; esac
