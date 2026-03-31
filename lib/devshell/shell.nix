{ nativePkgs, cfg }:

rec {
  inputrc = nativePkgs.writeText "devshell-inputrc" ''
    set editing-mode emacs
    set enable-keypad on
    "\e[A": history-search-backward
    "\e[B": history-search-forward
  '';

  bashrc = nativePkgs.writeText "devshell-bashrc" ''
    export INPUTRC=${inputrc}
    bind -f ${inputrc} 2>/dev/null

    HISTFILE="$ROOTFS/.bash_history"
    HISTSIZE=1000
    HISTFILESIZE=2000
    shopt -s histappend

    PS1='\[\033[1;32m\]\u@\h\[\033[0m\] \[\033[1;34m\]\w\[\033[0m\]\$ '
  '';
}