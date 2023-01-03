#!/usr/bin/env bash

# bash completion for LAMPP Version Manager (lamppvm)

if ! command -v lamppvm &> /dev/null; then
  return
fi

__lamppvm_generate_completion() {
  declare current_word
  current_word="${COMP_WORDS[COMP_CWORD]}"
  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "$1" -- "${current_word}"))
  return 0
}

__lamppvm_commands() {
  declare current_word
  declare command

  current_word="${COMP_WORDS[COMP_CWORD]}"

  COMMANDS='
    help install uninstall use list
    ls list-remote ls-remote current
    install-composer version where'

  if [ ${#COMP_WORDS[@]} == 4 ]; then

    command="${COMP_WORDS[COMP_CWORD - 2]}"
    case "${command}" in
      alias) __lamppvm_installed_nodes ;;
    esac

  else

    case "${current_word}" in
      -*) __lamppvm_options ;;
      *) __lamppvm_generate_completion "${COMMANDS}" ;;
    esac

  fi
}

__lamppvm_options() {
  OPTIONS=''
  __lamppvm_generate_completion "${OPTIONS}"
}

__lamppvm_installed_nodes() {
  __lamppvm_generate_completion "$(lamppvm_ls) $(__lamppvm_aliases)"
}

__lamppvm_aliases() {
  declare aliases
  aliases=""
  if [ -d "${lamppvm_DIR}/alias" ]; then
    aliases="$(command cd "${lamppvm_DIR}/alias" && command find "${PWD}" -type f | command sed "s:${PWD}/::")"
  fi
  echo "${aliases} node stable unstable iojs"
}

__lamppvm_alias() {
  __lamppvm_generate_completion "$(__lamppvm_aliases)"
}

__lamppvm() {
  declare previous_word
  previous_word="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${previous_word}" in
    use | run | exec | ls | list | uninstall) __lamppvm_installed_nodes ;;
    alias | unalias) __lamppvm_alias ;;
    *) __lamppvm_commands ;;
  esac

  return 0
}

if [[ -n ${ZSH_VERSION-} ]]; then
  if ! command -v compinit > /dev/null; then
    autoload -U +X compinit && if [[ ${ZSH_DISABLE_COMPFIX-} = true ]]; then
      compinit -u
    else
      compinit
    fi
  fi
  autoload -U +X bashcompinit && bashcompinit
fi

complete -o default -F __lamppvm lamppvm
