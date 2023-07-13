#compdef pass
#autoload

_name() {
    setopt histsubstpattern
    setopt extendedglob
    _values "password file name" $PASSWORD_STORE_DIR/**/*.gpg(:r:F:${#${(s:/:w)PASSWORD_STORE_DIR}}:s/#\\/[\^\\/]##//:s/#\\///)
}

_length() {
    _numbers
}

_pass() {
    local line state
    _arguments -C "1: :->cmds" "*::arg:->args"
    case "$state" in
        cmds)
            _values "pass command" "${(@f)$(pass help | sed -n \
                '/^    pass/{N;s/ *pass \([^ ]*\).*\n\s*\(.*\)/\1[\2]/p;}')}"
            ;;
        args)
            _arguments "${(@f)$(pass help \
                | awk -v comm="pass" -v subcomm="generate" -v FS='  +' '
                    /^    [^ ]/ {
                        relevant = match($0, " " subcomm);
                        if (!relevant) next;
                        split($0, args, " ")
                        for (i in args) {
                            if (args[i] == comm || args[i] == subcomm) continue;
                            if (match(args[i], /\.\.\./)) continue;
                            arg = substr(args[i], 2, length(args[i]) - 2)
                            print ":" arg ":_" arg
                        }
                    }
                    /^        -/ {
                        if (relevant) {
                            split($2, flags, ", ")
                            for (i in flags) {
                                print flags[i] "[" $3 "]"
                            }
                        }
                    }
                ')}";;
    esac
}

_pass