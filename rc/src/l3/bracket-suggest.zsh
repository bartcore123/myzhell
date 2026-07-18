#!/usr/bin/env zsh
# bracket-suggest.zsh
#
# Grey "ghost" suggestions for the closing ) } ] " ' you still owe, shown
# past the cursor the same way zsh-autosuggestions shows a command
# suggestion. Built on the same primitives that plugin uses (POSTDISPLAY +
# region_highlight), not on syntax-highlighting hacks.
#
# - RightArrow  -> inserts just the innermost pending closer
# - End / C-e   -> inserts every pending closer at once (fully balances the line)
#
# Install: source this file from your .zshrc, e.g.
#   source ~/.config/zsh/bracket-suggest.zsh
#
# Configure the color before sourcing, e.g.:
#   BRACKET_SUGGEST_STYLE='fg=242'

[[ -n $_BRACKET_SUGGEST_LOADED ]] && return
typeset -g _BRACKET_SUGGEST_LOADED=1

: ${BRACKET_SUGGEST_STYLE:=fg=8}

autoload -Uz add-zle-hook-widget

# ---------------------------------------------------------------------------
# Core: walk a string and return the "still open" closers, innermost first.
# ---------------------------------------------------------------------------
_bracket_suggest_stack_string() {
  emulate -L zsh
  local str=$1
  local -a stack
  local i=1 len=${#str} c top
  local prev_ws=1 in_comment=0

  while (( i <= len )); do
    c=${str[i]}

    if (( in_comment )); then
      # A comment eats everything up to the next real newline.
      if [[ $c == $'\n' ]]; then
        in_comment=0
        prev_ws=1
      fi
      (( i++ ))
      continue
    fi

    if (( $#stack )); then
      top=${stack[-1]}
    else
      top=''
    fi

    if [[ $top == '"' ]]; then
      # Inside a double-quoted string: only \ and the closing " matter.
      if [[ $c == '\' ]]; then
        (( i += 2 )); prev_ws=0; continue
      elif [[ $c == '"' ]]; then
        stack[-1]=()
      fi
    elif [[ $top == "'" ]]; then
      # Inside a single-quoted string: nothing is special but the closing '.
      # (single quotes don't support escaping at all, same as the shell)
      if [[ $c == "'" ]]; then
        stack[-1]=()
      fi
    else
      # Bare code context: everything counts.
      case $c in
        '\') (( i += 2 )); prev_ws=0; continue ;;
        '(') stack+=(')') ;;
        '{') stack+=('}') ;;
        '[') stack+=(']') ;;
        ')'|'}'|']')
          [[ $c == $top ]] && stack[-1]=()
          ;;
        '"') stack+=('"') ;;
        "'") stack+=("'") ;;
        # '#')
        #   # only a comment at the start of a word
        #   (( prev_ws )) && in_comment=1
        #   ;;
      esac
    fi

    case $c in
      ' '|$'\t'|$'\n'|';'|'|'|'&'|'('|')'|'{'|'}') prev_ws=1 ;;
      *) prev_ws=0 ;;
    esac
    (( i++ ))
  done

  # Innermost first: last pushed = first to show/accept.
  local out='' j
  for (( j = $#stack; j >= 1; j-- )); do
    out+=${stack[j]}
  done
  print -rn -- "$out"
}

# ---------------------------------------------------------------------------
# Display: keep POSTDISPLAY + region_highlight in sync on every redraw.
# ---------------------------------------------------------------------------
typeset -g _bracket_suggest_last_hl=""

_bracket_suggest_clear_hl() {
  if [[ -n $_bracket_suggest_last_hl ]]; then
    region_highlight=("${(@)region_highlight:#$_bracket_suggest_last_hl}")
    _bracket_suggest_last_hl=""
  fi
}

_bracket_suggest_update() {
  _bracket_suggest_clear_hl

  # POSTDISPLAY always renders at the true end of the buffer, not at the
  # literal cursor position, so we only show it while the cursor IS at the
  # end (no text to its right) -- otherwise it would show up in the wrong
  # place and look broken.
  if [[ -n $RBUFFER ]]; then
    POSTDISPLAY=
    return
  fi

  local suggestion
  suggestion=$(_bracket_suggest_stack_string "$BUFFER")

  if [[ -n $suggestion ]]; then
    POSTDISPLAY=$suggestion
    _bracket_suggest_last_hl="$#BUFFER $(( $#BUFFER + $#POSTDISPLAY )) $BRACKET_SUGGEST_STYLE"
    region_highlight+=("$_bracket_suggest_last_hl")
  else
    POSTDISPLAY=
  fi
}
add-zle-hook-widget line-pre-redraw _bracket_suggest_update

# ---------------------------------------------------------------------------
# Widgets
# ---------------------------------------------------------------------------
bracket-suggest-forward-char() {
  if [[ -n $RBUFFER ]]; then
    zle .forward-char   # real text to the right: behave normally
    return
  fi
  if [[ -n $POSTDISPLAY ]]; then
    LBUFFER+=${POSTDISPLAY[1]}   # innermost pending closer
  else
    zle .forward-char
  fi
}
zle -N bracket-suggest-forward-char

bracket-suggest-end-of-line() {
  zle .end-of-line
  local suggestion
  suggestion=$(_bracket_suggest_stack_string "$BUFFER")
  if [[ -n $suggestion ]]; then
    BUFFER+=$suggestion
    CURSOR=$[CURSOR+$#suggestion]
  fi
}
zle -N bracket-suggest-end-of-line

# ---------------------------------------------------------------------------
# Keybindings (emacs-style, zsh's interactive default)
# ---------------------------------------------------------------------------
bindkey '^[[C' bracket-suggest-forward-char
[[ -n ${terminfo[kcuf1]} ]] && bindkey "${terminfo[kcuf1]}" bracket-suggest-forward-char

bindkey '^[e' bracket-suggest-end-of-line
bindkey '^[[F' bracket-suggest-end-of-line
bindkey '^[[4~' bracket-suggest-end-of-line
[[ -n ${terminfo[kend]} ]] && bindkey "${terminfo[kend]}" bracket-suggest-end-of-line

# If you use vi keybindings too, uncomment:
# bindkey -M viins '^[[C' bracket-suggest-forward-char
# bindkey -M viins '^E' bracket-suggest-end-of-line
# bindkey -M viins '^[[F' bracket-suggest-end-of-line
# bindkey -M vicmd '^[[F' bracket-suggest-end-of-line
