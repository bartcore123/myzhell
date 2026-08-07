#!/usr/bin/env zsh
# smart-accept-line.zsh
#
# Replaces zsh's default Enter behaviour. Stock zsh: when the buffer is
# *incomplete* (unclosed {, (, ", etc.), Enter drops you into PS2
# continuation editing with a bare, unindented newline. This widget
# intercepts that and instead matches the indentation (leading tabs) of
# the line you were on, adding one further tab if that line opened a
# bracket that's still unmatched.
#
# Calibrated to sit alongside bracket-suggest.zsh: that plugin already
# shows you what closer you owe, as a purely VISUAL suggestion
# (POSTDISPLAY) that never becomes real buffer text until you explicitly
# accept it (RightArrow for one level, End / ^E for all of them). So this
# widget no longer inserts any closer itself -- it did, in an earlier
# version, and that's what caused the bug where pressing Enter while
# still "inside" an auto-closed block would silently accept and run the
# whole thing: the inserted closer was real buffer text, indistinguishable
# from anything you'd typed yourself, so the completeness check downstream
# saw a "finished" command. bracket-suggest.zsh's suggestion never has
# that problem because it was never in $BUFFER to begin with. Piggybacking
# on it here also means bracket-awareness only has to be correct in one
# place -- its scanner already handles quoting, comments, and $(...)/${...}
# inside double quotes properly, which my own first attempt didn't.
#
# A syntactically complete buffer still runs immediately, as before. A
# genuinely broken one still gets zsh's normal parse error, unchanged.
#
# Install: source both this file and bracket-suggest.zsh from .zshrc
# (either order -- this only calls into the other one at runtime, when
# you press Enter, not at source time). Source after
# zsh-syntax-highlighting / zsh-autosuggestions if you use those, so
# this has the last word on `accept-line`.

# ===========================================================================
# 1. Completeness test: is $1 something stock zsh would actually run,
#    or would it prompt for more (PS2 continuation)?
# ===========================================================================
#
# romkatv's technique from the zsh-no-ps2 plugin (MIT licensed,
# https://github.com/romkatv/zsh-no-ps2), reused close to verbatim here
# because it's meaningfully more reliable than anything built on
# pattern-matching `zsh -n`'s error text, and it runs entirely in-process
# -- no subshell per keypress.
#
# The trick: assigning a string directly to functions[somename] parses
# that string AS A FUNCTION BODY. If it's a well-formed compound list,
# the assignment succeeds (and briefly, really defines the function);
# if it's incomplete or malformed, the assignment fails. That's a cheap,
# accurate parser probe that never executes anything.
#
# A second pass catches two constructs ("for x" alone, or a bare heredoc
# marker) that parse fine as an isolated function body but would NOT
# actually run standalone in an interactive shell -- they'd still prompt
# for continuation. Appending "do\ndone" and re-testing flushes those
# out: if that changes the answer, the original wasn't really complete
# on its own.
#
# Returns 0 if "$1" is well-formed (stock zsh would run it), 1 if it's
# incomplete (or a trailing-backslash continuation).
_sal_probe_wellformed() {
  setopt local_options no_err_return no_err_exit
  () {
    () {
      builtin emulate -L zsh -o extended_glob
      [[ $1 == (|*[^\\])(\\\\)#\\ ]]
    } "$1" && builtin return 1

    if [[ -v functions[-sal-probe] ]]; then
      builtin unfunction -- -sal-probe
    fi
    functions[-sal-probe]="$1" 2>/dev/null || builtin return 1
    [[ -v functions[-sal-probe] ]] || builtin return 1
    builtin unfunction -- -sal-probe

    functions[-sal-probe]="$1"$'\ndo\ndone' 2>/dev/null || builtin return 0
    [[ -v functions[-sal-probe] ]] || builtin return 0
    builtin unfunction -- -sal-probe

    builtin return 1
  } "$1"
}

_sal_is_incomplete() {
  ! _sal_probe_wellformed "$1"
}

# ===========================================================================
# 2. Did the line I'm on just open something new?
# ===========================================================================
# Delegates to bracket-suggest.zsh's own _bracket_suggest_stack_string
# rather than re-scanning the buffer myself. That function returns the
# stack of pending closers as a string, innermost-first (e.g. ")}" means
# "close the paren, then eventually the brace"). Comparing the stack
# computed just before the current line started against the stack
# computed over the whole buffer tells us whether the current line added
# any new frames on top: if the "after" stack ends with the "before"
# stack unchanged, whatever's left over at the front is new, and came
# from this line specifically. That distinction matters -- without it,
# every plain line typed inside an already-open block would look like it
# just opened a bracket too, and get an extra indent it shouldn't.
#
# Falls back to "nothing new" (no extra indent) if bracket-suggest.zsh
# isn't loaded, so this file still degrades gracefully on its own.
_sal_opened_here() {
  (( ${+functions[_bracket_suggest_stack_string]} )) || return 1

  local cur_line=$1
  local before_line=${LBUFFER%"$cur_line"}
  local stack_before stack_after
  stack_before=$(_bracket_suggest_stack_string "$PREBUFFER$before_line")
  stack_after=$(_bracket_suggest_stack_string "$PREBUFFER$BUFFER")

  [[ $stack_after == *"$stack_before" ]] || return 1
  local new_part=${stack_after%"$stack_before"}
  [[ -n $new_part ]]
}

# ===========================================================================
# 3. The widget
# ===========================================================================
smart-accept-line() {
  emulate -L zsh

  # Only ever consider accepting/running when the cursor is truly at the
  # end of the buffer. If there's real text (or a not-yet-accepted
  # bracket-suggest POSTDISPLAY, which by construction only shows when
  # RBUFFER is empty anyway) to the right, Enter should just add a line,
  # the way it would in a normal editor -- never silently finish
  # whatever's below the cursor.
  if [[ -z $RBUFFER ]]; then
    if ! _sal_is_incomplete "$PREBUFFER$BUFFER"; then
      zle .accept-line
      return
    fi
  fi

  local cur_line=${LBUFFER##*$'\n'}
  local -i indent=0
  local scan=$cur_line
  while [[ $scan == $'\t'* ]]; do
    (( indent++ ))
    scan=${scan#$'\t'}
  done

  local -i new_indent=indent
  _sal_opened_here "$cur_line" && (( new_indent++ ))

  local new_tabs=''
  local -i n=new_indent
  while (( n-- > 0 )); do new_tabs+=$'\t'; done

  LBUFFER+=$'\n'"$new_tabs"
}
zle -N accept-line smart-accept-line
