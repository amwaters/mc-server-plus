#!/bin/bash
HELP="Downloads files.
download url <Url> <HashMethod> <Hash>
download minecraft <MinecraftVersion> <ObjectName>
download vanilla-tweaks <PackType> <MinecraftVersion> <PacksJson>
Example: download minecraft 1.18-pre3 server
"
REQUIREMENTS="curl jq unzip"
MANIFEST_URL="https://launchermeta.mojang.com/mc/game/version_manifest_v2.json"

set -e

# Gets a URL, dumps to stdout
function get_url {
    echo -n "Downloading $1 ... " >&2
    curl --silent "$1"
    echo "OK" >&2
}

# Performs a jq on stdin, dumps raw output to stdout
function jqr {
    jq --raw-output "$2" <<< "$1"
}

function assert_file {
    _METHOD="$1"
    _EXP="$2"
    _ACT="$3"
    if [ "$_EXP" == "$_ACT3" ]; then
        echo "  $_METHOD OK" >&2
    else
        echo "  $_METHOD FAILED" >&2
        echo "    Expected $_EXP" >&2
        echo "    Actual   $_ACT" >&2
        exit 1
    fi
}

function check_file {
    if [ "$1" == size ]; then
        assert_file "$1" "$3 $2" `wc -c "$2"`
    elif [ "$1" == sha1 ]; then
        assert_file "$1" "$3  $2" `sha1sum "$2"`
    elif [ "$1" == sha256 ]; then
        assert_file "$1" "$3  $2" `sha256sum "$2"`
    fi
}

# Gets a URL, verifies it, and saves it to current directory
function download_file {
    _URL="$1"
    shift

    # Use a temp file
    _TMP=`mktemp`
    (
        # Download file
        echo -n "Downloading $_URL ... " >&2
        curl --silent --output "$_TMP" "$_URL"
        echo "OK" >&2

        while [ ! -z "$1" ]; do
            check_file "$_TMP" "$1" "$2"
            shift ; shift
        done

        # Approve file
        _NAME="${_URL##*/}"
        mv "$_TMP" "./${_NAME}"

        # Executable if .jar
        [ "${_NAME##*.}" == "jar" ] \
            && chmod +x "./$_NAME" \
            || true
        echo "Download successful: ${_NAME}"

    ) && ( rm -f -- "$_TMP" ) \
      || ( RC=$?; rm -f -- "$_TMP"; exit $RC )
}



#######################
#  MINECRAFT OBJECTS

# Gets the manifest for a Minecraft version, dumps to stdout
function get_mc_version_manifest {
    _URL=` \
        get_url "$MANIFEST_URL" \
        | jq -r ".versions[] | select(.id==\"$1\").url" \
    `
    get_url "$_URL"
}

# Downloads a Minecraft object into the current directory.
function download_mc_object {
    _VER="$1"
    _KEY="$2"
    shift ; shift

    # Get manifest for required version
    _MAN=`get_mc_version_manifest "$_VER"`
    _URL=`jqr "$_MAN" ".downloads.${_KEY}.url"`
    _SIZE=`jqr "$_MAN" ".downloads.${_KEY}.size"`
    _SHA1=`jqr "$_MAN" ".downloads.${_KEY}.sha1"`

    download_file "$_URL" size "$_SIZE" sha1 "$_SHA1"
}



#######################
#  VANILLA TWEAKS

# Downloads a Vanilla Tweaks zip.
function download_vt_zip {
    _TYPE="$1"
    _VER="$2"
    _PACKS=`jq -c . <<< "$3"`

    _URL="https://vanillatweaks.net/assets/server/zip${_TYPE}.php"

    _TMP=`mktemp`
    (
        # Download file
        echo -n "Downloading Vanilla Tweaks ($_VER) ... " >&2
        _ZIP_RESPONSE="$( \
          curl -X POST \
            --form "version=$_VER" \
            --form "packs=$_PACKS" \
            --silent \
            "$_URL" )"
        echo "RESPONSE: $_ZIP_RESPONSE"
        if [ `jq -r '.status' <<< "$_ZIP_RESPONSE"` != "success" ]; then
            echo "Error from Vanilla Tweaks: $_ZIP_REPSONSE"
            exit 1
        fi
        _ZIP_URL=`jq -r '.link' <<< "$_ZIP_RESPONSE"`
        echo "ZIP URL: $_ZIP_URL" >&2
        curl --silent --output "$_TMP" "https://vanillatweaks.net/$_ZIP_URL"
        echo "TMP FILE: $_TMP" >&2

        # Extract file
        if [ "$_TYPE" == "datapacks" ]; then
            echo -n "Extracting Vanilla Tweaks ... " >&2
            mkdir -p "./vanilla-tweaks"
            unzip -od "./vanilla-tweaks" "$_TMP"
            echo "OK" >&2
        elif [ "$_TYPE" == "craftingtweaks" ]; then
            mv "$_TMP" "./vanilla-tweaks/craftingtweaks.zip"
        fi

    ) && ( rm -f -- "$_TMP" ) \
      || ( RC=$?; rm -f -- "$_TMP"; exit $RC )
}



##########
#  MAIN

function main {
    _SRC="$1"
    shift
    
    if [ "$_SRC" == url ]; then
        download_file "$@"
    elif [ "$_SRC" == minecraft ]; then
        download_mc_object "$@"
    elif [ "$_SRC" == "vanilla-tweaks" ]; then
        download_vt_zip "$@"
    fi
}

if [ "$1" == "--setup" ]; then
    echo -n "$REQUIREMENTS" | xargs apt-get install -y
    ln -s `realpath "$0"` /usr/local/bin/download
elif [ "$1" == "--help" ]; then
    echo "$HELP"
elif [ "$0" == "$BASH_SOURCE" ]; then
    main "$@"
fi
