function encode() {
    TITOLO="$1"
    DIR="$2"
    HandBrakeCLI -v --preset "High Profile" \
        --input "${DIR}/${TITOLO}" \
        --main-feature \
        --output "${DIR}/${TITOLO}.mkv" --format mkv --markers \
        --native-language ita \
        --subtitle scan \
        --subtitle-force scan
}

function iso() {
    TITOLO="$1"
    DIR="$2"
    mkisofs -dvd-video -udf -o "${DIR}/${TITOLO}.iso" "${DIR}/${TITOLO}"
}

function play() {
    TITOLO="$1"
    DIR="$2"
    ISO=$3
    SOURCE="${DIR}/${TITOLO}"
    if [[ $ISO == 1 ]]
    then
        SOURCE="${DIR}/${TITOLO}.iso"
    fi
    if [[ $ISO == 2 ]]
    then
        SOURCE="${DIR}/${TITOLO}.mkv"
    fi
    mplayer dvd:// -dvd-device "${SOURCE}"
}

function burn() {
    TITOLO="$1"
    DIR="$2"
    growisofs -Z "/dev/sr0"="${DIR}/${TITOLO}.iso"
}

rip "${TITOLO}" "${DIR}" 0
#encode "${TITOLO}" "${DIR}"
#iso "${TITOLO}" "${DIR}" 0
#play "${TITOLO}" "${DIR}"
#burn "${TITOLO}" "${DIR}"
exit 0

