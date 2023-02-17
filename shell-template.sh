#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Copyright 2020 Dave Jarvis
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# -----------------------------------------------------------------------------

set -o errexit
set -o nounset

readonly SCRIPT_SRC="$(dirname "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}")"
readonly SCRIPT_DIR="$(cd "${SCRIPT_SRC}" >/dev/null 2>&1 && pwd)"
readonly SCRIPT_NAME=$(basename "$0")

# -----------------------------------------------------------------------------
# The main entry point is responsible for parsing command-line arguments,
# changing to the appropriate directory, and running all commands requested
# by the user.
#
# $@ - Command-line arguments
# -----------------------------------------------------------------------------
main() {
  arguments "$@"

  $usage       && terminate 3
  requirements && terminate 4
  traps        && terminate 5

  directory    && terminate 6
  preprocess   && terminate 7
  execute      && terminate 8
  postprocess  && terminate 9

  terminate 0
}

# -----------------------------------------------------------------------------
# Perform all commands that the script requires.
#
# @return 0 - Indicate to terminate the script with non-zero exit level
# @return 1 - All tasks completed successfully (default)
# -----------------------------------------------------------------------------
execute() {
  return 1
}

# -----------------------------------------------------------------------------
# Changes to the script's working directory, provided it exists.
#
# @return 0 - Change directory failed
# @return 1 - Change directory succeeded
# -----------------------------------------------------------------------------
directory() {
  $log "Change directory"
  local result=1

  # Track whether change directory failed.
  cd "${SCRIPT_DIR}" > /dev/null 2>&1 || result=0

  return "${result}"
}

# -----------------------------------------------------------------------------
# Perform any initialization required prior to executing tasks.
#
# @return 0 - Preprocessing failed
# @return 1 - Preprocessing succeeded
# -----------------------------------------------------------------------------
preprocess() {
  $log "Preprocess"

  return 1
}

# -----------------------------------------------------------------------------
# Perform any clean up required prior to executing tasks.
#
# @return 0 - Postprocessing failed
# @return 1 - Postprocessing succeeded
# -----------------------------------------------------------------------------
postprocess() {
  $log "Postprocess"

  return 1
}

# -----------------------------------------------------------------------------
# Check that all required commands are available.
#
# @return 0 - At least one command is missing
# @return 1 - All commands are available
# -----------------------------------------------------------------------------
requirements() {
  $log "Verify requirements"
  local -r expected_count=${#DEPENDENCIES[@]}
  local total_count=0

  # Verify that each command exists.
  for dependency in "${DEPENDENCIES[@]}"; do
    # Extract the command name [0] and URL [1].
    IFS=',' read -ra dependent <<< "${dependency}"

    required "${dependent[0]}" "${dependent[1]}"
    total_count=$(( total_count + $? ))
  done

  unset IFS

  # Total dependencies found must match the expected number.
  # Integer-only division rounds down.
  return $(( total_count / expected_count ))
}

# -----------------------------------------------------------------------------
# Called before terminating the script.
# -----------------------------------------------------------------------------
cleanup() {
  $log "Cleanup"
}

# -----------------------------------------------------------------------------
# Terminates the program immediately.
# -----------------------------------------------------------------------------
trap_control_c() {
  $log "Interrupted"
  cleanup
  error "⯃"
  terminate 1
}

# -----------------------------------------------------------------------------
# Configure signal traps.
#
# @return 1 - Signal traps are set.
# -----------------------------------------------------------------------------
traps() {
  # Suppress echoing ^C if pressed.
  stty -echoctl
  trap trap_control_c INT

  return 1
}

# -----------------------------------------------------------------------------
# Check for a required command.
#
# $1 - Command or file to check for existence
# $2 - Command's website (e.g., download for binaries and source code)
#
# @return 0 - Command is missing
# @return 1 - Command exists
# -----------------------------------------------------------------------------
required() {
  local result=0

  test -f "$1" || \
  command -v "$1" > /dev/null 2>&1 && result=1 || \
    warning "Missing: $1 ($2)"

  return ${result}
}

# -----------------------------------------------------------------------------
# Show acceptable command-line arguments.
#
# @return 0 - Indicate script may not continue
# -----------------------------------------------------------------------------
utile_usage() {
  printf "Usage: %s [OPTIONS...]\n\n" "${SCRIPT_NAME}" >&2

  # Number of spaces to pad after the longest long argument.
  local -r PADDING=2

  # Determine the longest long argument to adjust spacing.
  local -r LEN=$(printf '%s\n' "${ARGUMENTS[@]}" | \
    awk -F"," '{print length($2)+'${PADDING}'}' | sort -n | tail -1)

  local duplicates

  for argument in "${ARGUMENTS[@]}"; do
    # Extract the short [0] and long [1] arguments and description [2].
    arg=("$(echo ${argument} | cut -d ',' -f1)" \
         "$(echo ${argument} | cut -d ',' -f2)" \
         "$(echo ${argument} | cut -d ',' -f3-)")

    duplicates+=("${arg[0]}")

    printf "  -%s, --%-${LEN}s%s\n" "${arg[0]}" "${arg[1]}" "${arg[2]}" >&2
  done

  # Sort the arguments to make sure no duplicates exist.
  duplicates=$(echo "${duplicates[@]}" | tr ' ' '\n' | sort | uniq -c -d)

  # Warn the developer that there's a duplicate command-line option.
  if [ -n "${duplicates}" ]; then
    # Trim all the whitespaces
    duplicates=$(echo "${duplicates}" | xargs echo -n)
    error "Duplicate command-line argument exists: ${duplicates}"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Write coloured text to standard output.
#
# $1 - Text to write
# $2 - Text's colour
# -----------------------------------------------------------------------------
coloured_text() {
  printf "%b%s%b\n" "$2" "$1" "${COLOUR_OFF}"
}

# -----------------------------------------------------------------------------
# Write a warning message to standard output.
#
# $1 - Text to write
# -----------------------------------------------------------------------------
warning() {
  coloured_text "$1" "${COLOUR_WARNING}"
}

# -----------------------------------------------------------------------------
# Write an error message to standard output.
#
# $1 - Text to write
# -----------------------------------------------------------------------------
error() {
  coloured_text "$1" "${COLOUR_ERROR}"
}

# -----------------------------------------------------------------------------
# Write a timestamp and message to standard output.
#
# $1 - Text to write
# -----------------------------------------------------------------------------
utile_log() {
  printf "[%s] " "$(date +%H:%M:%S.%4N)"
  coloured_text "$1" "${COLOUR_LOGGING}"
}

# -----------------------------------------------------------------------------
# Perform no operations.
#
# return 1 - Success
# -----------------------------------------------------------------------------
noop() {
  return 1
}

# -----------------------------------------------------------------------------
# Exit the program with a given exit code.
#
# $1 - Exit code
# -----------------------------------------------------------------------------
terminate() {
  exit "$1"
}

# -----------------------------------------------------------------------------
# Set global variables from command-line arguments.
# -----------------------------------------------------------------------------
arguments() {
  while [ "$#" -gt "0" ]; do
    local consume=1

    case "$1" in
      -V|--verbose)
        log=utile_log
      ;;
      -h|-\?|--help)
        usage=utile_usage
      ;;
      *)
        set +e
        argument "$@"
        consume=$?
        set -e
      ;;
    esac

    shift ${consume}
  done
}

# -----------------------------------------------------------------------------
# Parses a single command-line argument. This must return a value greater
# than or equal to 1, otherwise parsing the command-line arguments will
# loop indefinitely.
#
# @return The number of arguments to consume (1 by default).
# -----------------------------------------------------------------------------
argument() {
  return 1
}

# ANSI colour escape sequences.
readonly COLOUR_BLUE='\033[1;34m'
readonly COLOUR_PINK='\033[1;35m'
readonly COLOUR_DKGRAY='\033[30m'
readonly COLOUR_DKRED='\033[31m'
readonly COLOUR_LTRED='\033[1;31m'
readonly COLOUR_YELLOW='\033[1;33m'
readonly COLOUR_OFF='\033[0m'

# Colour definitions used by script.
COLOUR_LOGGING=${COLOUR_BLUE}
COLOUR_WARNING=${COLOUR_YELLOW}
COLOUR_ERROR=${COLOUR_LTRED}

# Define required commands to check when script starts.
DEPENDENCIES=(
  "awk,https://www.gnu.org/software/gawk/manual/gawk.html"
  "cut,https://www.gnu.org/software/coreutils"
)

# Define help for command-line arguments.
ARGUMENTS=(
  "V,verbose,Log messages while processing"
  "h,help,Show this help message then exit"
)

# These functions may be set to utile delegates while parsing arguments.
usage=noop
log=noop
