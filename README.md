# MDM Lab

Or, how to speedrun setting up a self-hosted MDM server using the following components:

- [Traefik](https://traefik.io) as a reverse proxy and load balancer
- [micromdm/scep](https://github.com/micromdm/scep) as a certificate authority and SCEP server for issuing device certificates
- [postgres](https://www.postgresql.org) as a database for nanomdm
- [nanomdm](https://github.com/micromdm/nanomdm) as an MDM server
- [kmfddm](https://github.com/jessepeterson/kmfddm) as a declarative device management server, connected to nanomdm

## BYOx

You will need to provide:

1. A linux server with a public IP address, 1vCPU and 1GB of memory is plenty for a small test environment
1. Ports 80 and 443 open and unused on the server
1. Docker and Docker Compose installed on the server
1. A wildcard DNS A record for a new subdomain (e.g. *.mdm.yourdomain.com) pointing to the server's IP address

## Setup

1. Clone this repo onto your server, change directory into it
1. Create a copy of `mdm-lab.env.example` named `mdm-lab.env`
1. Edit the new file and fill in the values for each variable

## Load Balancer

Traefik will be configured to watch for new docker containers and automatically register routers and services based on their labels. We'll see this in action as we bring up the other services. Each service will be issued a TLS certificate from Let's Encrypt and Traefik will renew them before they expire.

Traefik's service and access logs will be saved in the `load-balancer/logs` subdirectory. Let's Encrypt certificates will be saved in the `load-balancer/certs` directory so they can be reused after ther service restarts.

1. Change into the `load-balancer` directory from the root of the repo
1. Run `docker compose --env-file ../mdm-lab.env up -d` to bring up the traefik load balancer
1. Once the service has started, the traefik dashboard will be available at `https://traefik.<your domain name>/dashboard/` and automatically issued a Let's Encrypt certificate
1. Sign in with the username and password you created in the environment file
1. Click "Explore" on the HTTP "Routers" card and we'll see two routers, one for let's encrypt challenges and one for the traefik dashboard itself
1. Select either of the routers to see more details about them

The load balancer is now online and ready to handle requests for our other services. Next we'll bring up the certificate authority and SCEP server.

## Certificate Authority

A certificate authority will be configured to accept SCEP requests from devices and issue certificates to them. On the first start the CA will be initialized.

The CA public certificate, private key, and client certificates will all be saved in the `certificate-authority/ca` directory.

1. Change into the `certificate-authority` directory from the root of the repo
1. Run `docker compose --env-file ../mdm-lab.env  up -d` to build and bring up the certificate authority, the first time the service starts it will create a new CA certificate and key which will be saved in the `ca` directory
1. Return to the traefik dashboard routers page and observe the new router for the CA service

Your SCEP server is now available at `https://ca.<your domain>` and you can use it to issue certificates to your devices. We can now move on to the MDM server!

## MDM

NanoMDM data will be stored in a postgres database and will use the certificate authority's public key to validate device enrollments. On the first start the database will be initialized and the schema will be created.

KMFDDM will be connected to the NanoMDM api and will store all data as files on the host in the `nanomdm/ddm_data` directory so they can be easily inspected.

1. Change into the `nanomdm` directory from the root of the repo
1. Create a new subdirectory `data` with `mkdir data`
1. Save a copy of the CA's public certificate into this directory for nanomdm to use: `cp ../certificate-authority/ca/ca.pem data/ca.pem`
1. View the certificate with `less data/ca.pem`
1. Bring up the postgres database with `docker compose --env-file ../mdm-lab.env  up -d postgres` and allow it to initialize the database tables
1. We can follow the postgres logs with `docker compose --env-file ../mdm-lab.env  logs -f postgres` and watch for the line `LOG:  database system is ready to accept connections` before continuing
1. Bring up the remaining nanomdm and kmfddm services with `docker compose --env-file ../mdm-lab.env up -d`
1. Return to the traefik dashboard routers page and observe the new routers for the nanomdm and kmfddm services

NanoMDM is now available at `https://nanomdm.<your domain>`, and KMFDDM is available at `https://ddm.<your domain>`.

Logs for each service are available via `docker compose --env-file ../mdm-lab.env  logs --follow [kmfddm|nanomdm|postgres]`.

## Next Steps

With all of these services running, you can now:

1. [Create the required MDM certificates and upload the push cert to nanomdm](https://github.com/micromdm/nanomdm/blob/main/docs/quickstart.md#upload-push-certificate)
1. [Create an enrollment profile based on this example](https://github.com/micromdm/nanomdm/blob/main/docs/quickstart.md#configure-enrollment-profile)
1. [Enroll test devices and start managing them, declaratively](https://github.com/jessepeterson/kmfddm/blob/main/docs/quickstart.md#setup-environment)!
