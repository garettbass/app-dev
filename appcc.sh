#!/usr/bin/env

CMDLINE="$0 $@"

#-------------------------------------------------------------------------------

function usage {
    echo "Usage:"
    echo ""
    echo "  sh $0 [options] <sources> [-- ...]"
    echo ""
    echo "Options:"
    echo ""
    echo "  -g     Generate debug symbols."
    echo "  -O<x>  Optimization levels: 0, 1, 2, 3, fast, s"
    echo "  --     Run the compiled app, and pass remaining arguments."
    echo ""
}

#-------------------------------------------------------------------------------

function verbose {
    if [ $VERBOSE ]; then
        echo "$@"
    fi
}

#-------------------------------------------------------------------------------

function execute {
    verbose "$@"
    if [ $TIME ]; then
        time "$@"
    else
        "$@"
    fi
}

#-------------------------------------------------------------------------------

function realpath {
    local path="${1//\\//}"
    if [ "$path" == "." ]; then
        echo "$(pwd)"
    elif [ "$path" == ".." ]; then
        echo "$(dirname "$(pwd)")"
    else
        echo "$(cd "$(dirname "$path")"; pwd)/$(basename "$path")"
    fi
}

#-------------------------------------------------------------------------------

if [ -z "$CC" ]; then
    CC="$(which cc)"
    if [ ! -f "$CC" ]; then
        CC="$(which gcc)"
        if [ ! -f "$CC" ]; then
            CC="$(which clang)"
        fi
    fi
fi

#-------------------------------------------------------------------------------

CFLAGS="${CFLAGS:=-Werror}"

#-------------------------------------------------------------------------------

SOURCES=()
while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            usage
            exit 1
        ;;
        -g)
            CFLAGS="$CFLAGS -D_DEBUG=1 $1"
            shift
        ;;
        -D*|-O*|-std=*)
            CFLAGS="$CFLAGS $1"
            shift
        ;;
        -x)
            CFLAGS="$CFLAGS $1 $2"
            shift
            shift
        ;;
        -t)
            TIME=YES
            shift
        ;;
        -v)
            VERBOSE=YES
            CFLAGS="$CFLAGS -DVERBOSE=1"
            shift
        ;;
        --clean)
            CLEAN=YES
            shift
        ;;
        --)
            RUN=YES
            CLEAN=YES
            shift
            break
        ;;
        -*)
            echo "unrecognized option: $1"
            echo ""
            usage
            exit 1
        ;;
        *)
            SOURCE="$(realpath $1)"
            SOURCES+=("$SOURCE")
            shift
        ;;
    esac
done

if [ ! $SOURCES ]; then
    usage
    exit 1
fi

#-------------------------------------------------------------------------------

verbose "$CMDLINE"

#-------------------------------------------------------------------------------

APP_MAIN="${SOURCES[0]}"
APP_ROOT="$(dirname $APP_MAIN)"
APP_NAME="$(basename ${APP_MAIN%.*})"

case $(uname | tr '[:upper:]' '[:lower:]') in
    linux*)
        APP_HOST_OS=linux
    ;;
    darwin*)
        APP_HOST_OS=macos
        BIN="$APP_ROOT/app.app/Contents/MacOS/app"
        CLEANUP="rm -f $BIN; rm -rf $APP_ROOT/app.app/Contents/MacOS/app.dSYM"
    ;;
    msys*|mingw*)
        APP_HOST_OS=windows
        CFLAGS="${CFLAGS} -D_CRT_SECURE_NO_WARNINGS"
        BIN="$APP_ROOT/$APP_NAME.exe"
        CLEANUP="rm -f ${BIN}; rm -f ${BIN%.*}.ilk; rm -f ${BIN%.*}.pdb"
    ;;
    *)
        echo "unrecognized operating system"
        exit 1
    ;;
esac

#-------------------------------------------------------------------------------

COMPILE="$CC $CFLAGS ${SOURCES[@]} -o $BIN"
execute $COMPILE
STATUS=$?
if [ $STATUS -gt 0 ]; then exit $STATUS; fi

#-------------------------------------------------------------------------------

if [ $RUN ]; then
    echo $''
    verbose "$BIN" "$@"
    "$BIN" "$@"
    STATUS=$?
    echo $''
    echo "$BIN" returned "$STATUS"
fi

if [ $CLEAN ]; then
    rm -f  "${BIN}"
    rm -f  "${BIN%.*}.ilk"
    rm -f  "${BIN%.*}.pdb"
    rm -rf "${APP_ROOT}/app.app/Contents/MacOS/app.dSYM"
fi

#-------------------------------------------------------------------------------

exit $STATUS

#-------------------------------------------------------------------------------
