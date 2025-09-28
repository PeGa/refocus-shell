_refocus_prompt() {
  # remember baseline once
  if [[ -z "${REFOCUS_BASE_PS1+x}" ]]; then REFOCUS_BASE_PS1="$PS1"; fi

  local dir="${REFOCUS_STATE_DIR:-$HOME/.local/refocus}"
  local cache="$dir/prompt.cache"
  local verfile="$dir/prompt.ver"

  # default: no segment
  local seg="" st proj mins

  if [[ -r "$cache" ]]; then
    IFS='|' read -r st proj mins <"$cache" || true

    if [[ "$st" == "on" ]]; then
      # LIVE minutes: recompute from start.ts every time (ignore ver gate)
      local start_ts now_ts
      if [[ -r "$dir/start.ts" ]]; then
        start_ts="$(<"$dir/start.ts")"
      fi
      if [[ -z "$start_ts" ]]; then
        # optional fallback: parse from DB or cache mins as-is
        start_ts=""
      fi
      now_ts="$(date +%s)"
      if [[ "$start_ts" =~ ^[0-9]+$ ]]; then
        mins="$(( (now_ts - start_ts) / 60 ))"
        (( mins < 0 )) && mins=0
      elif [[ -z "${mins:-}" || "$mins" == "-" ]]; then
        mins=0
      fi
      [[ -z "$proj" || "$proj" == "-" ]] && proj="(no project)"
      seg="⏳ ${proj} (${mins}m)"
    else
      # OFF/IDLE: only rebuild if version changed (cheap)
      local ver=0; [[ -r "$verfile" ]] && ver=$(<"$verfile")
      [[ -z "${__REFOCUS_LAST_VER:-}" ]] && __REFOCUS_LAST_VER=-1
      if [[ "$ver" == "$__REFOCUS_LAST_VER" ]]; then
        return
      fi
      __REFOCUS_LAST_VER="$ver"
    fi
  fi

  # rebuild from baseline
  if [[ -n "$seg" ]]; then
    PS1="[${seg}] ${REFOCUS_BASE_PS1%\\$ }"
  else
    PS1="$REFOCUS_BASE_PS1"
  fi
}

case ":${PROMPT_COMMAND:-}:" in *":_refocus_prompt:"*) ;; *) PROMPT_COMMAND="_refocus_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}";; esac