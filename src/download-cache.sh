#!/bin/bash
download url https://raw.githubusercontent.com/Freaky/run-one/e6b4720b8debbfe83f7e2e6650439382ada3993a/run-one sha256 ae9d8388f52ce450dfbaaf297c8e333d40c9817b3a402c9ce6b1df88f447724a
download minecraft "${MC_VERSION}" server
download minecraft "${MC_VERSION}" client
