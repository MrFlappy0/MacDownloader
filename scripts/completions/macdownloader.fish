function __fish_macdownloader_needs_command
    for i in (commandline -opc)
        if contains -l $i download d info i batch b list l --help -h --version -v
            return 0
        end
    end
    return 1
end

function __fish_macdownloader_using_command
    for i in (commandline -opc)
        if contains -l $i download d info i batch b list l
            return 0
        end
    end
    return 1
end

function __fish_macdownloader_quality_options
    echo 1080p 720p 480p 360p HD SD auto
end

function __fish_macdownloader_commands
    echo download d info i batch b list l help
end

function __fish_macdownloader_common_options
    echo --help -h --version -v
end

function __fish_macdownloader_download_options
    echo -q --quality -o --output -n --filename --overwrite --no-progress
end

function __fish_macdownloader_info_options
    echo -q --quality --json
end

function __fish_macdownloader_batch_options
    echo -f --file -o --output -q --quality --overwrite
end

complete -c macdownloader -n "__fish_macdownloader_needs_command" -a "(__fish_macdownloader_commands) (__fish_macdownloader_common_options)"

complete -c macdownloader -n "__fish_macdownloader_using_command" -s d -a "(__fish_macdownloader_download_options)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s download -a "(__fish_macdownloader_download_options)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s i -a "(__fish_macdownloader_info_options)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s info -a "(__fish_macdownloader_info_options)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s b -a "(__fish_macdownloader_batch_options)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s batch -a "(__fish_macdownloader_batch_options)"

complete -c macdownloader -n "__fish_macdownloader_using_command" -s q -a "(__fish_macdownloader_quality_options)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s --quality -a "(__fish_macdownloader_quality_options)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s o -a "(__fish_complete_directories)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s --output -a "(__fish_complete_directories)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s f -a "(__fish_complete_files)"
complete -c macdownloader -n "__fish_macdownloader_using_command" -s --file -a "(__fish_complete_files)"
