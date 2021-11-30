# MC Server Plus

*More than just a Minecraft server!*


## Features

+ Microservice architecture
+ Automated backups
+ Version control via build arguments
+ Settings control via environment variables
+ Fetches latest datapacks from [Vanilla Tweaks](https://vanillatweaks.net/)


## Prerequisites

+ [Git](https://git-scm.com/downloads)
+ [Docker](https://docs.docker.com/get-docker/)
+ [Docker Compose](https://docs.docker.com/compose/install/)


## Quick Start

1. Clone the repo: `git clone https://github.com/amwaters/mc-server-plus.git`
2. Modify `docker-compose.yaml` to suit your needs
3. In the repo root directory, run the server via Docker Compose: `docker compose up --build --detach`
3. Follow the logs: `docker compose logs --follow`


## Microservices

+ `mc-server`: The primary Minecraft server
+ `world-backup`: Makes regular backups


### Roadmap

+ Server optimisations
+ Parallel dimension loading utility
+ Client-side mod builds and other resources
+ Additional resource pack management
+ `web-proxy`: A reverse proxy for the microservices network
+ `mapper`: Generates maps from world data
+ `mapper-web`: Web app for viewing maps in near-real-time
