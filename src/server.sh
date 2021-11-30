#!/bin/bash
HELP="Runs the Minecraft server."
REQUIREMENTS="gettext-base"

set -e

source server.env

function main {

    (
      mkdir -p minecraft
      cd minecraft

      ln -fs `realpath ../server.jar` server.jar

      mkdir -p ./world
      ln -fs `realpath ../datapacks` ./world/datapacks
      #cp -fr ../datapacks/* ./world/datapacks

      cat ../server.properties  \
        | envsubst              \
        > server.properties
      
      echo "eula=$ACCEPT_EULA" > eula.txt

      java                  \
        "-Xmx$JAVA_MEMORY"  \
        -jar server.jar     \
          --nogui
    )
}

if [ "$1" == "--setup" ]; then
    echo -n "$REQUIREMENTS" | xargs apt-get install -y
elif [ "$1" == "--help" ]; then
    echo "$HELP"
elif [ "$0" == "$BASH_SOURCE" ]; then
    main "$@"
fi
