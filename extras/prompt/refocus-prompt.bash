# Source this from ~/.bashrc

_refocus_prompt() {
  # --- baseline: remember original prompt once ---
  if [[ -z "${REFOCUS_BASE_PS1+x}" ]]; then
    REFOCUS_BASE_PS1="$PS1"
  fi

  local dir="${REFOCUS_STATE_DIR:-$HOME/.local/refocus}"
  local verfile="$dir/prompt.ver" cache="$dir/prompt.cache"
  [[ -z "${__REFOCUS_LAST_VER:-}" ]] && __REFOCUS_LAST_VER=0

  # --- fast exit if no change ---
  local ver=0; [[ -r "$verfile" ]] && ver=$(<"$verfile")
  if [[ "$ver" == "$__REFOCUS_LAST_VER" ]]; then
    # No change: keep current PS1 as-is (already built from baseline earlier)
    return
  fi
  __REFOCUS_LAST_VER="$ver"

  # --- build segment from cache ---
  local seg=""
  if [[ -r "$cache" ]]; then
    IFS='|' read -r st proj mins <"$cache" || true
    if [[ "$st" == "on" ]]; then
      [[ -z "$proj" || "$proj" == "-" ]] && proj="(no project)"
      [[ -z "$mins" || "$mins" == "-" ]] && mins="0"
      seg="⏳ ${proj} (${mins}m)"
    fi
  fi

  # --- rebuild PS1 from baseline every time ---
  if [[ -n "$seg" ]]; then
    # prepend segment to baseline
    PS1="[${seg}] ${REFOCUS_BASE_PS1%\\$ }"
  else
    PS1="$REFOCUS_BASE_PS1"
  fi
}

# Ensure we only register once
case ":$PROMPT_COMMAND:" in
  *":_refocus_prompt:"*) ;;
  *) PROMPT_COMMAND="_refocus_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}";;
esac