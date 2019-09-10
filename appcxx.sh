#!/usr/bin/env

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

if [ -z "$CXX" ]; then
    CXX="$(which c++)"
    if [ ! -f "$CXX" ]; then
        CXX="$(which g++)"
        if [ ! -f "$CXX" ]; then
            CXX="$(which clang++)"
        fi
    fi
fi

#-------------------------------------------------------------------------------

CXXFLAGS="${CXXFLAGS:=-std=c++11 -Werror -Wno-comment}"

#-------------------------------------------------------------------------------

SOURCES=()
while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            usage
            exit 1
        ;;
        -g)
            CXXFLAGS="$CXXFLAGS -D_DEBUG=1 $1"
            shift
        ;;
        -O*)
            CXXFLAGS="$CXXFLAGS $1"
            shift
        ;;
        -t)
            TIME=YES
            shift
        ;;
        -v)
            VERBOSE=YES
            shift
        ;;
        --)
            RUN=YES
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
            SOURCES+=("$1")
            shift
        ;;
    esac
done

if [ ! $SOURCES ]; then
    usage
    exit 1
fi

#-------------------------------------------------------------------------------

APP_MAIN="${SOURCES[0]}"
APP_ROOT="$(dirname $APP_MAIN)"
APP_NAME="${APP_MAIN%.*}"

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
        CXXFLAGS="${CXXFLAGS} -D_CRT_SECURE_NO_WARNINGS"
        BIN="$APP_ROOT/$APP_NAME.exe"
        CLEANUP="rm -f ${BIN}; rm -f ${BIN%.*}.ilk; rm -f ${BIN%.*}.pdb"
    ;;
    *)
        echo "unrecognized operating system"
        exit 1
    ;;
esac

#-------------------------------------------------------------------------------

COMPILE="$CXX $CXXFLAGS ${SOURCES[@]} -o $BIN"
execute $COMPILE
STATUS=$?
if [ $STATUS -gt 0 ]; then exit $STATUS; fi

#-------------------------------------------------------------------------------

if [ $RUN ]; then
    echo $''
    verbose "$BIN" "$@"
    "$BIN" "$@"
    STATUS=$?

    rm -f  "${BIN}"
    rm -f  "${BIN%.*}.ilk"
    rm -f  "${BIN%.*}.pdb"
    rm -rf "${APP_ROOT}/app.app/Contents/MacOS/app.dSYM"

    echo $''
    echo "$BIN" returned "$STATUS"
fi

#-------------------------------------------------------------------------------

exit $STATUS

#-------------------------------------------------------------------------------
