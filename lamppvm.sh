{
    lampp_echo() {
        command printf %s\\n "$*" 2>/dev/null
    }

    lamppvm() {
        lampp_echo "Hello World"
    }
}
