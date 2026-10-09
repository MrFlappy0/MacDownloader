_macdownloader() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help -h --version -v download d info i batch b list l"
    commands="download info batch list help"
    
    case "${prev}" in
        macdownloader)
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
            return 0
            ;;
        -q|--quality)
            COMPREPLY=($(compgen -W "1080p 720p 480p 360p HD SD auto" -- ${cur}))
            return 0
            ;;
        -o|--output)
            COMPREPLY=($(compgen -f -- ${cur}))
            return 0
            ;;
        -f|--file)
            COMPREPLY=($(compgen -f -- ${cur}))
            return 0
            ;;
        download|d|info|i|batch|b)
            COMPREPLY=($(compgen -W "-q --quality -o --output -n --filename --overwrite --no-progress --help -h" -- ${cur}))
            return 0
            ;;
        *)
            COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
            return 0
            ;;
    esac
}

complete -F _macdownloader macdownloader
