#!/usr/bin/env bash

if [[ "$1" == "--help" || "$1" == "-h" || "$#" -lt 1 ]]; then
    echo "  ___  ______  _____                                      "
    echo " / _ \ | ___ \/  __ \                                     "
    echo "/ /_\ \| |_/ /| /  \/                                     "
    echo "|  _  ||    / | |                                         "
    echo "| | | || |\ \ | \__/\                                     "
    echo "\_| |_/\_| \_| \____/                                     "
    echo "                                                          "
    echo "                                                          "
    echo "   ______                                                 "
    echo "   |  _  \                                                "
    echo "   | | | |___  ___ ___  _ __ ___  _ __  _ __ ___  ___ ___ "
    echo "   | | | / _ \/ __/ _ \| '_ \` _ \| '_ \| '__/ _ \/ __/ __|"
    echo "   | |/ /  __/ (_| (_) | | | | | | |_) | | |  __/\__ \__ \\"
    echo "   |___/ \___|\___\___/|_| |_| |_| .__/|_|  \___||___/___/"
    echo "                                 | |                      "
    echo "                                 |_|                      "
    echo ""
    echo "Arc - A simple bash script for compressing and decompressing files"
    echo ""
    echo "Author - Israel G. Albuquerque"
    echo "GitHub -  https://github.com/leoisrael"
    echo ""
    echo "Usage:"
    echo "  arc compress [options] [format] [output_name] [files...]"
    echo "  arc decompress [options] [file]"
    echo "  arc list [file]"
    echo "Options:"
    echo "  -p, --password [password]    Set a password for encrypted archives"
    echo "Formats:"
    echo "  zip, tar, tar.gz, tar.bz2, tar.xz, 7z"
    exit 1
fi

command="$1"
shift

function initialize_environment() {
    TEMP_DIR="/tmp/arc_$$"
    mkdir -p "$TEMP_DIR"
    LOG_FILE="$TEMP_DIR/arc.log"
    touch "$LOG_FILE"
    PASSWORD=""
}

function cleanup_environment() {
    rm -rf "$TEMP_DIR"
}

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

function validate_files() {
    for file in "${files[@]}"; do
        if [ ! -e "$file" ]; then
            echo "File '$file' does not exist."
            log "File '$file' does not exist."
            cleanup_environment
            exit 1
        fi
    done
}

function check_dependencies() {
    dependencies=(zip unzip tar 7z)
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            echo "Dependency '$dep' is not installed."
            log "Dependency '$dep' is not installed."
            cleanup_environment
            exit 1
        fi
    done
}

function parse_options() {
    while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
        -p | --password )
            shift; PASSWORD="$1"
            ;;
    esac; shift; done
    if [[ "$1" == '--' ]]; then shift; fi
    set -- "$@"
    echo "$@"
}

function generate_temp_filename() {
    echo "$TEMP_DIR/$(date +%s%N)"
}

function compress() {
    options=()
    format="$1"
    shift
    output="$1"
    shift
    files=("$@")
    validate_files
    if [ -n "$PASSWORD" ]; then
        case "$format" in
            zip)
                options+=("-e" "-P" "$PASSWORD")
                ;;
            7z)
                options+=("-p$PASSWORD")
                ;;
            *)
                echo "Password protection not supported for format: $format"
                log "Password protection not supported for format: $format"
                cleanup_environment
                exit 1
                ;;
        esac
    fi
    case "$format" in
        zip)
            zip "${options[@]}" -r "$output.zip" "${files[@]}" >/dev/null
            ;;
        tar)
            tar -cf "$output.tar" "${files[@]}"
            ;;
        tar.gz)
            tar -czf "$output.tar.gz" "${files[@]}"
            ;;
        tar.bz2)
            tar -cjf "$output.tar.bz2" "${files[@]}"
            ;;
        tar.xz)
            tar -cJf "$output.tar.xz" "${files[@]}"
            ;;
        7z)
            7z a "${options[@]}" "$output.7z" "${files[@]}" >/dev/null
            ;;
        *)
            echo "Unsupported format: $format"
            log "Unsupported format: $format"
            cleanup_environment
            exit 1
            ;;
    esac
    echo "Files compressed into $output.$format"
    log "Files compressed into $output.$format"
}

function decompress() {
    options=()
    file="$1"
    if [ ! -f "$file" ]; then
        echo "File '$file' not found!"
        log "File '$file' not found!"
        cleanup_environment
        exit 1
    fi
    dirname="${file%.*}"
    mkdir -p "$dirname"
    extension="${file##*.}"
    if [ -n "$PASSWORD" ]; then
        case "$extension" in
            zip)
                options+=("-P" "$PASSWORD")
                ;;
            7z)
                options+=("-p$PASSWORD")
                ;;
            *)
                echo "Password input not supported for format: $extension"
                log "Password input not supported for format: $extension"
                cleanup_environment
                exit 1
                ;;
        esac
    fi
    case "$extension" in
        zip)
            unzip "${options[@]}" -qq "$file" -d "$dirname"
            ;;
        tar)
            tar -xf "$file" -C "$dirname"
            ;;
        gz|tgz)
            tar -xzf "$file" -C "$dirname"
            ;;
        bz2|tbz2)
            tar -xjf "$file" -C "$dirname"
            ;;
        xz|txz)
            tar -xJf "$file" -C "$dirname"
            ;;
        7z)
            7z x "${options[@]}" "$file" -o"$dirname" >/dev/null
            ;;
        *)
            echo "Unsupported file format: $file"
            log "Unsupported file format: $file"
            cleanup_environment
            exit 1
            ;;
    esac
    echo "Files extracted to $dirname/"
    log "Files extracted to $dirname/"
}

function list_contents() {
    file="$1"
    if [ ! -f "$file" ]; then
        echo "File '$file' not found!"
        log "File '$file' not found!"
        cleanup_environment
        exit 1
    fi
    extension="${file##*.}"
    case "$extension" in
        zip)
            unzip -l "$file"
            ;;
        tar|gz|tgz|bz2|tbz2|xz|txz)
            tar -tf "$file"
            ;;
        7z)
            7z l "$file"
            ;;
        *)
            echo "Unsupported file format: $file"
            log "Unsupported file format: $file"
            cleanup_environment
            exit 1
            ;;
    esac
    log "Listed contents of $file"
}

function show_progress() {
    PID=$1
    spin='-\|/'
    i=0
    while kill -0 $PID 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\rProcessing... ${spin:$i:1}"
        sleep .1
    done
    printf "\r"
}

initialize_environment
check_dependencies

case "$command" in
    compress)
        args=$(parse_options "$@")
        set -- $args
        if [ "$#" -lt 3 ]; then
            echo "Usage: arc compress [options] [format] [output_name] [files...]"
            log "Incorrect usage of compress command"
            cleanup_environment
            exit 1
        fi
        format="$1"; shift
        output="$1"; shift
        log "Starting compression"
        compress "$format" "$output" "$@" &
        PID=$!
        show_progress $PID
        wait $PID
        ;;
    decompress)
        args=$(parse_options "$@")
        set -- $args
        if [ "$#" -ne 1 ]; then
            echo "Usage: arc decompress [options] [file]"
            log "Incorrect usage of decompress command"
            cleanup_environment
            exit 1
        fi
        file="$1"
        log "Starting decompression"
        decompress "$file" &
        PID=$!
        show_progress $PID
        wait $PID
        ;;
    list)
        if [ "$#" -ne 1 ]; then
            echo "Usage: arc list [file]"
            log "Incorrect usage of list command"
            cleanup_environment
            exit 1
        fi
        file="$1"
        log "Listing contents of $file"
        list_contents "$file"
        ;;
    *)
        echo "Unknown command: $command"
        echo "Use 'arc --help' for usage information."
        log "Unknown command: $command"
        cleanup_environment
        exit 1
        ;;
esac

cleanup_environment
