{
    lamppvm_has() {
        type "$1" >/dev/null 2>&1
    }

    lamppvm_echo() {
        command printf %s\\n "$*" 2>/dev/null
    }

    if [ -z "${BASH_VERSION}" ] || [ -n "${ZSH_VERSION}" ]; then
        # shellcheck disable=SC2016
        lamppvm_echo >&2 'Error: the install instructions explicitly say to pipe the install script to `bash`; please follow them'
        exit 1
    fi

    lamppvm_grep() {
        GREP_OPTIONS='' command grep "$@"
    }

    lamppvm_default_install_dir() {
        [ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.lamppvm" || printf %s "${XDG_CONFIG_HOME}/lamppvm"
    }

    lamppvm_default_dev_install_dir() {
        [ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.lamppvm_dev" || printf %s "${XDG_CONFIG_HOME}/lamppvm_dev"
    }

    lamppvm_install_dir() {
        if [ -n "$LAMPPVM_DIR" ]; then
            printf %s "${LAMPPVM_DIR}"
        else
            lamppvm_default_install_dir
        fi
    }
    lamppvm_dev_install_dir() {
        if [ -n "$LAMPPVM_DIR" ]; then
            printf %s "${LAMPPVM_DIR}"
        else
            lamppvm_default_dev_install_dir
        fi
    }

    lamppvm_latest_version() {
        lamppvm_echo "v0.0.1"
    }

    lamppvm_source() {
        local LAMPPVM_GITHUB_REPO
        LAMPPVM_GITHUB_REPO="${LAMPPVM_INSTALL_GITHUB_REPO:-midlajc/lamppvm}"
        local LAMPPVM_VERSION
        LAMPPVM_VERSION="${LAMPPVM_INSTALL_VERSION:-$(lamppvm_latest_version)}"
        local LAMPPVM_METHOD
        LAMPPVM_METHOD="$1"
        local LAMPPVM_SOURCE_URL
        LAMPPVM_SOURCE_URL="$LAMPPVM_SOURCE"
        if [ "_$LAMPPVM_METHOD" = "_script-lamppvm-exec" ]; then
            LAMPPVM_SOURCE_URL="https://raw.githubusercontent.com/${LAMPPVM_GITHUB_REPO}/${LAMPPVM_VERSION}/lamppvm-exec.sh"
        elif [ "_$LAMPPVM_METHOD" = "_script-lamppvm-bash-completion" ]; then
            LAMPPVM_SOURCE_URL="https://raw.githubusercontent.com/${LAMPPVM_GITHUB_REPO}/${LAMPPVM_VERSION}/bash_completion.sh"
        elif [ -z "$LAMPPVM_SOURCE_URL" ]; then
            if [ "_$LAMPPVM_METHOD" = "_script" ]; then
                LAMPPVM_SOURCE_URL="https://raw.githubusercontent.com/${LAMPPVM_GITHUB_REPO}/${LAMPPVM_VERSION}/lamppvm.sh"
            elif [ "_$LAMPPVM_METHOD" = "_git" ] || [ -z "$LAMPPVM_METHOD" ]; then
                LAMPPVM_SOURCE_URL="https://github.com/${LAMPPVM_GITHUB_REPO}.git"
            else
                lamppvm_echo >&2 "Unexpected value \"$LAMPPVM_METHOD\" for \$LAMPPVM_METHOD"
                return 1
            fi
        fi
        lamppvm_echo "$LAMPPVM_SOURCE_URL"
    }

    lamppvm_try_profile() {
        if [ -z "${1-}" ] || [ ! -f "${1}" ]; then
            return 1
        fi
        lamppvm_echo "${1}"
    }

    #
    # Detect profile file if not specified as environment variable
    # (eg: PROFILE=~/.myprofile)
    # The echo'ed path is guaranteed to be an existing file
    # Otherwise, an empty string is returned
    #
    lamppvm_detect_profile() {
        if [ "${PROFILE-}" = '/dev/null' ]; then
            # the user has specifically requested NOT to have lamppvm touch their profile
            return
        fi

        if [ -n "${PROFILE}" ] && [ -f "${PROFILE}" ]; then
            lamppvm_echo "${PROFILE}"
            return
        fi

        local DETECTED_PROFILE
        DETECTED_PROFILE=''

        if [ "${SHELL#*bash}" != "$SHELL" ]; then
            if [ -f "$HOME/.bashrc" ]; then
                DETECTED_PROFILE="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                DETECTED_PROFILE="$HOME/.bash_profile"
            fi
        elif [ "${SHELL#*zsh}" != "$SHELL" ]; then
            if [ -f "$HOME/.zshrc" ]; then
                DETECTED_PROFILE="$HOME/.zshrc"
            elif [ -f "$HOME/.zprofile" ]; then
                DETECTED_PROFILE="$HOME/.zprofile"
            fi
        fi

        if [ -z "$DETECTED_PROFILE" ]; then
            for EACH_PROFILE in ".profile" ".bashrc" ".bash_profile" ".zprofile" ".zshrc"; do
                if DETECTED_PROFILE="$(lamppvm_try_profile "${HOME}/${EACH_PROFILE}")"; then
                    break
                fi
            done
        fi

        if [ -n "$DETECTED_PROFILE" ]; then
            lamppvm_echo "$DETECTED_PROFILE"
        fi
    }

    lamppvm_profile_is_bash_or_zsh() {
        local TEST_PROFILE
        TEST_PROFILE="${1-}"
        case "${TEST_PROFILE-}" in
        *"/.bashrc" | *"/.bash_profile" | *"/.zshrc" | *"/.zprofile")
            return
            ;;
        *)
            return 1
            ;;
        esac
    }

    install_lamppvm_dev() {
        local INSTALL_DIR
        INSTALL_DIR="$(lamppvm_dev_install_dir)"
        if [ -d $INSTALL_DIR ]; then
            local INSTALL_DIR_SYM_LINK
            INSTALL_DIR_SYM_LINK="$(command readlink $INSTALL_DIR)"
            if [ "${INSTALL_DIR_SYM_LINK} = "${PROJECT_PATH} ]; then
                lamppvm_echo >&2 "Symlink already exist."
            else
                if [ -e "${INSTALL_DIR}" ]; then
                    lamppvm_echo >&2 "File \"${INSTALL_DIR}\" has the same name as installation directory."
                    exit 1
                fi

                if ! [ "${LAMPPVM_DIR}" = "$(lamppvm_default_install_dir)" ]; then
                    lamppvm_echo >&2 "You have \$LAMPPVM_DIR set to \"${LAMPPVM_DIR}\", but that directory does not exist. Check your profile files and environment."
                    exit 1
                fi
            fi
        else
            command ln -s "$PROJECT_PATH" "$INSTALL_DIR"
            lamppvm_echo >&2 "Symlink Created."
        fi
    }

    install_lamppvm_from_git() {
        local INSTALL_DIR
        INSTALL_DIR="$(lamppvm_install_dir)"
        local LAMPPVM_VERSION
        LAMPPVM_VERSION="${LAMPPVM_INSTALL_VERSION:-$(lamppvm_latest_version)}"
        # Check if version is an existing ref
        if ! command git ls-remote "$(lamppvm_source "git")" "$LAMPPVM_VERSION" | lamppvm_grep -q "$LAMPPVM_VERSION"; then
            lamppvm_echo >&2 "Failed to find '$LAMPPVM_VERSION' version."
            exit 1
        fi

        local fetch_error
        if [ -d "$INSTALL_DIR/.git" ]; then
            # Updating repo
            lamppvm_echo "=> lamppvm is already installed in $INSTALL_DIR, trying to update using git"
            command printf '\r=> '
            fetch_error="Failed to update lamppvm with $LAMPPVM_VERSION, run 'git fetch' in $INSTALL_DIR yourself."
        else
            fetch_error="Failed to fetch origin with $LAMPPVM_VERSION. Please report this!"
            lamppvm_echo "=> Downloading lamppvm from git to '$INSTALL_DIR'"
            command printf '\r=> '
            mkdir -p "${INSTALL_DIR}"
            if [ "$(ls -A "${INSTALL_DIR}")" ]; then
                # Initializing repo
                command git init "${INSTALL_DIR}" || {
                    lamppvm_echo >&2 'Failed to initialize lamppvm repo. Please report this!'
                    exit 2
                }
                command git --git-dir="${INSTALL_DIR}/.git" remote add origin "$(lamppvm_source)" 2>/dev/null ||
                    command git --git-dir="${INSTALL_DIR}/.git" remote set-url origin "$(lamppvm_source)" || {
                    lamppvm_echo >&2 'Failed to add remote "origin" (or set the URL). Please report this!'
                    exit 2
                }
            else
                # Cloning repo
                command git clone "$(lamppvm_source)" --depth=1 "${INSTALL_DIR}" || {
                    lamppvm_echo >&2 'Failed to clone lamppvm repo. Please report this!'
                    exit 2
                }
            fi
        fi
        # Try to fetch tag
        if command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" fetch origin tag "$LAMPPVM_VERSION" --depth=1 2>/dev/null; then
            :
        # Fetch given version
        elif ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" fetch origin "$LAMPPVM_VERSION" --depth=1; then
            lamppvm_echo >&2 "$fetch_error"
            exit 1
        fi
        command git -c advice.detachedHead=false --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" checkout -f --quiet FETCH_HEAD || {
            lamppvm_echo >&2 "Failed to checkout the given version $LAMPPVM_VERSION. Please report this!"
            exit 2
        }
        if [ -n "$(command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" show-ref refs/heads/master)" ]; then
            if command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet 2>/dev/null; then
                command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet -D master >/dev/null 2>&1
            else
                lamppvm_echo >&2 "Your version of git is out of date. Please update it!"
                command git --no-pager --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch -D master >/dev/null 2>&1
            fi
        fi

        lamppvm_echo "=> Compressing and cleaning up git repository"
        if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" reflog expire --expire=now --all; then
            lamppvm_echo >&2 "Your version of git is out of date. Please update it!"
        fi
        if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" gc --auto --aggressive --prune=now; then
            lamppvm_echo >&2 "Your version of git is out of date. Please update it!"
        fi
        return
    }

    lamppvm_do_install() {
        METHOD='dev'
        PROJECT_PATH='/home/midlajc/workspace/projects/lamppvm'
        local LAMPPVM_PROFILE
        local PROFILE_INSTALL_DIR

        if [ -n "${LAMPPVM_DIR-}" ] && ! [ -d "${LAMPPVM_DIR}" ]; then
            if [ -e "${LAMPPVM_DIR}" ]; then
                lamppvm_echo >&2 "File \"${LAMPPVM_DIR}\" has the same name as installation directory."
                exit 1
            fi

            if [ "${LAMPPVM_DIR}" = "$(lamppvm_default_install_dir)" ]; then
                mkdir "${LAMPPVM_DIR}"
            else
                lamppvm_echo >&2 "You have \$LAMPPVM_DIR set to \"${LAMPPVM_DIR}\", but that directory does not exist. Check your profile files and environment."
                exit 1
            fi
        fi

        if [ -z "${METHOD}" ]; then
            if lamppvm_has git; then
                install_lamppvm_from_git
                PROFILE_INSTALL_DIR="$(lamppvm_install_dir | command sed "s:^$HOME:\$HOME:")"
            else
                lamppvm_echo >&2 'You need git to install lamppvm'
                exit 1
            fi
        elif [ "${METHOD}" = 'dev' ]; then
            install_lamppvm_dev
            PROFILE_INSTALL_DIR="$(lamppvm_dev_install_dir | command sed "s:^$HOME:\$HOME:")"
        else
            lamppvm_echo >&2 "The environment variable \$METHOD is set to \"${METHOD}\", which is not recognized as a valid installation method."
            exit 1
        fi

        lamppvm_echo

        LAMPPVM_PROFILE="$(lamppvm_detect_profile)"

        SOURCE_STR="\\nexport LAMPPVM_DIR=\"${PROFILE_INSTALL_DIR}\"\\n[ -s \"\$LAMPPVM_DIR/lamppvm.sh\" ] && \\. \"\$LAMPPVM_DIR/lamppvm.sh\"  # This loads lamppvm\\n"

        # shellcheck disable=SC2016
        COMPLETION_STR='[ -s "$LAMPPVM_DIR/bash_completion.sh" ] && \. "$LAMPPVM_DIR/bash_completion.sh"  # This loads lamppvm bash_completion\n'
        BASH_OR_ZSH=false

        if [ -z "${LAMPPVM_PROFILE-}" ]; then
            local TRIED_PROFILE
            if [ -n "${PROFILE}" ]; then
                TRIED_PROFILE="${LAMPPVM_PROFILE} (as defined in \$PROFILE), "
            fi
            lamppvm_echo "=> Profile not found. Tried ${TRIED_PROFILE-}~/.bashrc, ~/.bash_profile, ~/.zprofile, ~/.zshrc, and ~/.profile."
            lamppvm_echo "=> Create one of them and run this script again"
            lamppvm_echo "   OR"
            lamppvm_echo "=> Append the following lines to the correct file yourself:"
            command printf "${SOURCE_STR}"
            lamppvm_echo
        else
            if lamppvm_profile_is_bash_or_zsh "${LAMPPVM_PROFILE-}"; then
                BASH_OR_ZSH=true
            fi
            if ! command grep -qc '/lamppvm.sh' "$LAMPPVM_PROFILE"; then
                lamppvm_echo "=> Appending lamppvm source string to $LAMPPVM_PROFILE"
                command printf "${SOURCE_STR}" >>"$LAMPPVM_PROFILE"
            else
                lamppvm_echo "=> lamppvm source string already in ${LAMPPVM_PROFILE}"
            fi
            # shellcheck disable=SC2016
            if ${BASH_OR_ZSH} && ! command grep -qc '$LAMPPVM_DIR/bash_completion.sh' "$LAMPPVM_PROFILE"; then
                lamppvm_echo "=> Appending bash_completion.sh source string to $LAMPPVM_PROFILE"
                command printf "$COMPLETION_STR" >>"$LAMPPVM_PROFILE"
            else
                lamppvm_echo "=> bash_completion.sh source string already in ${LAMPPVM_PROFILE}"
            fi
        fi
        if ${BASH_OR_ZSH} && [ -z "${LAMPPVM_PROFILE-}" ]; then
            lamppvm_echo "=> Please also append the following lines to the if you are using bash/zsh shell:"
            command printf "${COMPLETION_STR}"
        fi

        lamppvm_echo "=> Close and reopen your terminal to start using lamppvm or run the following to use it now:"
        command printf "${SOURCE_STR}"
        if ${BASH_OR_ZSH}; then
            command printf "${COMPLETION_STR}"
        fi
    }

    lamppvm_do_install
}
