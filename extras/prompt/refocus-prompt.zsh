_refocus_precmd() {
  local dir="${REFOCUS_STATE_DIR:-$HOME/.local/refocus}"
  local cache="$dir/prompt.cache" verfile="$dir/prompt.ver"
  typeset -g REFOCUS_BASE_RPROMPT
  [[ -z $REFOCUS_BASE_RPROMPT ]] && REFOCUS_BASE_RPROMPT="$RPROMPT"

  local seg="" st proj mins
  if [[ -r $cache ]]; then
    IFS='|' read -r st proj mins <"$cache"
    if [[ "$st" == "on" ]]; then
      local start_ts now_ts
      [[ -r "$dir/start.ts" ]] && start_ts=$(<"$dir/start.ts")
      now_ts=$EPOCHSECONDS
      if [[ "$start_ts" == <-> ]]; then
        mins=$(( (now_ts - start_ts) / 60 ))
        (( mins < 0 )) && mins=0
      elif [[ -z "$mins" || "$mins" == "-" ]]; then
        mins=0
      fi
      [[ -z "$proj" || "$proj" == "-" ]] && proj="(no project)"
      seg="⏳ ${proj} (${mins}m)"
    else
      # only rebuild if ver changed
      typeset -g REFOCUS_LAST_VER; [[ -z $REFOCUS_LAST_VER ]] && REFOCUS_LAST_VER=-1
      local ver=0; [[ -r $verfile ]] && ver=$(<"$verfile")
      [[ "$ver" == "$REFOCUS_LAST_VER" ]] && return
      REFOCUS_LAST_VER="$ver"
    fi
  fi
  RPROMPT="${REFOCUS_BASE_RPROMPT}${seg:+ $seg}"
}
precmd_functions+=(_refocus_precmd)