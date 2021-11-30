#####################
#  BUILD ARGUMENTS

ARG IMAGE=optimised-server
ARG MC_VERSION=1.18-rc3
ARG OPEN_JDK_VERSION=17.0
ARG DEBIAN_VERSION=bullseye
ARG VT_VERSION=1.17
ARG VT_DATAPACKS=
ARG VT_CRAFTING=
ARG LEGACY_ADVANCEMENTS=



###########################
#  BASE JAVA ENVIRONMENT

FROM openjdk:${OPEN_JDK_VERSION}-slim-${DEBIAN_VERSION} AS java-base
WORKDIR /app
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y tini
ENTRYPOINT [ "/usr/bin/tini", "--" ]



#######################
#  DEBIAN BASE IMAGE

FROM debian:${DEBIAN_VERSION}-slim AS deb-base
WORKDIR /app
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y tini
ENTRYPOINT [ "/usr/bin/tini", "--" ]



##################################
#  ASSORTED FILE DOWNLOAD CACHE

# This cache avoids requiring curl, jq in various containers

FROM deb-base AS download-cache
ARG MC_VERSION
ARG VT_VERSION
ARG VT_DATAPACKS
ARG VT_CRAFTING
ARG LEGACY_ADVANCEMENTS
WORKDIR /app
COPY ./download.sh .
COPY ./download-cache.sh .
RUN chmod +x download.sh download-cache.sh && ./download.sh --setup
WORKDIR /cache
RUN /app/download-cache.sh



###################
#  BASE CRON JOB

# Usage:
#   CMD [ "<Minute Hour DayOfMonth Month DayOfWeek>", "<Command>" ]

FROM deb-base AS cron-base
WORKDIR /app

COPY --from=download-cache /cache/run-one .
COPY ./cron-entrypoint.sh .
RUN chmod +x run-one cron-entrypoint.sh && ./cron-entrypoint.sh --setup

ENTRYPOINT [ "/usr/bin/tini", "--", "/app/cron-entrypoint.sh" ]



############################
#  BASE BUILD ENVIRONMENT

FROM deb-base AS build
WORKDIR /src
RUN apt-get install -y \
    build-essential cmake check debhelper-compat dpkg-dev git libbsd-dev \
    libglib2.0-dev



###############################
#  RCON COMMAND LINE UTILITY

# Builds the rcon command line installer.
# Output:
#   /rcon.deb
# Usage:
#   COPY --from=rcon-build /rcon.deb .
#   RUN apt-get install -y ./rcon.deb

FROM build AS rcon-build
RUN git clone https://github.com/n0la/rcon.git
WORKDIR /src/rcon
RUN dpkg-buildpackage -b -uc -us \
&&  mv ../rcon_*.deb /rcon.deb



######################
#  WORLD BACKUP JOB

# Regularly backs up /app/minecraft to /app/backups

FROM cron-base AS world-backup
COPY --from=rcon-build /rcon.deb .
RUN apt-get install -y ./rcon.deb
COPY ./world-backup.sh .
RUN chmod +x world-backup.sh && ./world-backup.sh --setup
# 16 UTC = 2AM AEST, 3AM AEDT
CMD [ "0 16 * * *", "/app/run-one /app/world-backup.sh" ]



##############################
#  VANILLA MINECRAFT SERVER

FROM java-base AS vanilla-server
ARG MC_VERSION
ARG ACCEPT_EULA
WORKDIR /app

COPY --from=download-cache /cache/server.jar .

COPY ./server.env .
COPY ./server.properties .
COPY ./server.sh .
RUN chmod +x server.sh && ./server.sh --setup

EXPOSE 25565
EXPOSE 25575

CMD [ "/app/server.sh" ]


####################################
#  MOD-OPTIMISED MINECRAFT SERVER

FROM vanilla-server AS vanilla-server-datapacks
WORKDIR /app
COPY --from=download-cache /cache/vanilla-tweaks/* /app/datapacks/
COPY --from=download-cache LegacyAdvancements.zip* /app/datapacks/


#############################################
#  VANILLA MINECRAFT SERVER WITH DATAPACKS

FROM vanilla-server-datapacks AS optimised-server
WORKDIR /app





FROM ${IMAGE}
