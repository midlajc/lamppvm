# lamppvm



```sh
curl -o- https://raw.githubusercontent.com/midlajc/lamppvm/v0.0.1/install.sh | bash
```
```sh
wget -o- https://raw.githubusercontent.com/midlajc/lamppvm/v0.0.1/install.sh | bash
```

### Append this with .bashrc or .zsh
```sh
export LAMPP_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.lamppvm" || printf %s "${XDG_CONFIG_HOME}/lamppvm")"
[ -s "$LAMPP_DIR/lamppvm.sh" ] && \. "$LAMPP_DIR/lamppvm.sh" # This loads lamppvm
```
