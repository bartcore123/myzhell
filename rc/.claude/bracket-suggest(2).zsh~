#!/usr/bin/env zsh
# bracket-suggest.zsh
#
# Grey "ghost" suggestions for the closing ) } ] " ' you still owe, shown
# past the cursor the same way zsh-autosuggestions shows a command
# suggestion. Built on the same primitives that plugin uses (POSTDISPLAY +
# region_highlight), not on syntax-highlighting hacks.
#
# - RightArrow  -> inserts just the innermost pending closer (or, if that
#                  opener was typed with a space right after it, the space
#                  plus the closer together -- see "space padding" below)
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
#
# This is a tiny hand-rolled parser, not a regex. At every position it's in
# exactly one of three "modes", decided purely by what's on top of the
# stack:
#   - top is `"`  -> we're inside a double-quoted string
#   - top is `'`  -> we're inside a single-quoted string
#   - anything else (including an empty stack) -> plain "code" context
#
# Three parallel arrays track one thing each, per currently-open frame:
#   stack       the character we're waiting for, to close that frame
#   stack_pad   1 if that opener was typed with a space right after it
#               (so its closer should render with a mirroring space, e.g.
#               "{ " suggests " }" instead of "}")
#   stack_brk1  only meaningful for a `]` frame: counts down how many of
#               the immediately-following characters are the POSIX
#               "leading ] is literal" exception (see the '[' case below)
# Every push appends to all three in lockstep; every pop removes the last
# element of all three. That's the only invariant to keep in mind if you
# want to add a fourth kind of "per-frame" tracking later.
# ---------------------------------------------------------------------------
_bracket_suggest_stack_string() {
  emulate -L zsh
  local str=$1
  local -a stack stack_pad stack_brk1
  local i=1 len=${#str} c top
  local prev_ws=1 prev_dollar=0 in_comment=0

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
      # Inside a double-quoted string. Almost everything here is just
      # literal text -- BUT double quotes still let $(...), ${...}, and
      # $((...)) through, and those need real matching too (that's the
      # bug you hit: "${ was being swallowed as inert string content).
      # We only need to notice a "$" immediately followed by "(" or "{";
      # once that pushes a frame, top is no longer '"' or "'", so every
      # character after that is handled by the ordinary code-mode branch
      # below, fully respecting whatever quotes/brackets show up inside
      # the substitution -- and we land back in "dq" mode automatically
      # once that inner frame closes, because top reverts to '"' again.
      if [[ $c == '\' ]]; then
        (( i += 2 )); prev_ws=0; prev_dollar=0; continue
      elif [[ $c == '"' ]]; then
        stack[-1]=(); stack_pad[-1]=(); stack_brk1[-1]=()
      elif (( prev_dollar )) && [[ $c == '(' ]]; then
        stack+=(')')
        if [[ ${str[i+1]} == ' ' ]]; then stack_pad+=(1); else stack_pad+=(0); fi
        stack_brk1+=(0)
      elif (( prev_dollar )) && [[ $c == '{' ]]; then
        stack+=('}')
        if [[ ${str[i+1]} == ' ' ]]; then stack_pad+=(1); else stack_pad+=(0); fi
        stack_brk1+=(0)
      fi

    elif [[ $top == "'" ]]; then
      # Inside a single-quoted string: nothing is special but the closing '.
      # (Single quotes suppress every expansion, $ included -- unlike
      # double quotes, there's no $(/${ exception to make here.)
      if [[ $c == "'" ]]; then
        stack[-1]=(); stack_pad[-1]=(); stack_brk1[-1]=()
      fi

    elif [[ $top == ']' ]] && (( ${stack_brk1[-1]:-0} > 0 )); then
      # See the '[' case below: we precomputed that the next 1-2
      # characters are the POSIX "leading ] is literal" exception, so
      # just burn through them without treating them as special at all.
      stack_brk1[-1]=$(( stack_brk1[-1] - 1 ))

    else
      # Bare code context: everything counts.
      case $c in
        '\') (( i += 2 )); prev_ws=0; prev_dollar=0; continue ;;
        '(')
          stack+=(')')
          if [[ ${str[i+1]} == ' ' ]]; then stack_pad+=(1); else stack_pad+=(0); fi
          stack_brk1+=(0)
          ;;
        '{')
          stack+=('}')
          if [[ ${str[i+1]} == ' ' ]]; then stack_pad+=(1); else stack_pad+=(0); fi
          stack_brk1+=(0)
          ;;
        '[')
          stack+=(']')
          if [[ ${str[i+1]} == ' ' ]]; then stack_pad+=(1); else stack_pad+=(0); fi
          # POSIX bracket-expression quirk: a ']' immediately after '[' (or
          # after a negating '^'/'!') is a literal member of the set, not
          # the closer -- e.g. []abc] and [^]abc] both need a *second* ']'
          # to actually close. This applies to shell's own glob brackets
          # too (rm file[0-9]*, *.[ch], [[:alpha:]]), not just sed/grep.
          if [[ ${str[i+1]} == '^' || ${str[i+1]} == '!' ]]; then
            if [[ ${str[i+2]} == ']' ]]; then stack_brk1+=(2); else stack_brk1+=(1); fi
          elif [[ ${str[i+1]} == ']' ]]; then
            stack_brk1+=(1)
          else
            stack_brk1+=(0)
          fi
          ;;
        ')'|'}'|']')
          if [[ $c == $top ]]; then
            stack[-1]=(); stack_pad[-1]=(); stack_brk1[-1]=()
          fi
          ;;
        '"')
          stack+=('"')
          stack_pad+=(0)   # never space-pad quotes: a mirrored space would
          stack_brk1+=(0)  # land *inside* the string and change its value
          ;;
        "'")
          stack+=("'")
          stack_pad+=(0)
          stack_brk1+=(0)
          ;;
        '#')
          # only a comment at the start of a word
          (( prev_ws )) && in_comment=1
          ;;
      esac
    fi

    case $c in
      ' '|$'\t'|$'\n'|';'|'|'|'&'|'('|')'|'{'|'}') prev_ws=1 ;;
      *) prev_ws=0 ;;
    esac
    if [[ $c == '$' ]]; then
      prev_dollar=1
    else
      prev_dollar=0
    fi
    (( i++ ))
  done

  # Innermost first: last pushed = first to show/accept. A padded frame's
  # closer gets a leading space (see stack_pad above).
  local out='' j
  for (( j = $#stack; j >= 1; j-- )); do
    (( stack_pad[j] )) && out+=' '
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
    # A leading space means the innermost frame was padded -- accept the
    # space and its closer together as one unit, not as two separate presses.
    if [[ ${POSTDISPLAY[1]} == ' ' ]]; then
      LBUFFER+=${POSTDISPLAY[1,2]}
    else
      LBUFFER+=${POSTDISPLAY[1]}
    fi
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
    CURSOR=$#BUFFER
  fi
}
zle -N bracket-suggest-end-of-line

# ---------------------------------------------------------------------------
# Keybindings (emacs-style, zsh's interactive default)
# ---------------------------------------------------------------------------
bindkey '^[[C' bracket-suggest-forward-char
[[ -n ${terminfo[kcuf1]} ]] && bindkey "${terminfo[kcuf1]}" bracket-suggest-forward-char

bindkey '^E' bracket-suggest-end-of-line
bindkey '^[[F' bracket-suggest-end-of-line
bindkey '^[[4~' bracket-suggest-end-of-line
[[ -n ${terminfo[kend]} ]] && bindkey "${terminfo[kend]}" bracket-suggest-end-of-line

# If you use vi keybindings too, uncomment:
# bindkey -M viins '^[[C' bracket-suggest-forward-char
# bindkey -M viins '^E' bracket-suggest-end-of-line
# bindkey -M viins '^[[F' bracket-suggest-end-of-line
# bindkey -M vicmd '^[[F' bracket-suggest-end-of-line
