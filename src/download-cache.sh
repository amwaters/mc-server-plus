#!/bin/bash
set -e

download url https://raw.githubusercontent.com/Freaky/run-one/e6b4720b8debbfe83f7e2e6650439382ada3993a/run-one sha256 ae9d8388f52ce450dfbaaf297c8e333d40c9817b3a402c9ce6b1df88f447724a
download minecraft "${MC_VERSION}" server
download minecraft "${MC_VERSION}" client

if [ ! -z "$LEGACY_ADVANCEMENTS" ]; then
    download url https://legacysmp.com/LegacyAdvancements.zip sha256 48165e26848cde49fc61b5af35ffdeec9770d22d3f986170231cac6f1e180e5a
fi

if [ ! -z "$VT_DATAPACKS" ]; then
    download vanilla-tweaks datapacks "$VT_VERSION" "$VT_DATAPACKS"
fi

if [ ! -z "$VT_CRAFTING" ]; then
    download vanilla-tweaks craftingtweaks "$VT_VERSION" "$VT_CRAFTING"
fi
