This repository contains the application source and CI/CD infrastructure for a Node Express Hello app. For the CI/CD pipeline, it uses Jenkins, Docker (in Docker), and a local Docker registry on a Linux VM.

## Jenkins Setup

1. **Docker Network**

```
docker network create jenkins
```

2. **Docker‑in‑Docker (DIND) Container**

```
docker run -d \
  --name jenkins-docker \
  --restart=always \
  --privileged \
  --network jenkins --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  docker:dind --storage-driver overlay2 --insecure-registry registry:5000 
```

3. **Jenkins Master Container**

```
docker run -d \
  --name jenkins-blueocean \
  --restart=on-failure \
  --network jenkins \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  -v jenkins-data:/var/jenkins_home \
  -v jenkins-docker-certs:/certs/client:ro \
  -p 8080:8080 -p 50000:50000 \
  localhost:5000/myjenkins-blueocean:2.504.1-1
```

4. **Initial Configuration**
	- Unlock Jenkins using the password from `/var/jenkins_home/secrets/initialAdminPassword`.
    - Install suggested plugins (includes Pipeline, Git, Blue Ocean, Timestamper, etc.).
    - Create an admin user and configure credentials.

## Docker Registry Setup

Run a local registry on port 5000:

```
docker run -d \
  --name registry \
  --restart=always \
  --network jenkins \
  -p 5000:5000 \
  -v registry-data:/var/lib/registry \
  registry:2
```

Verify the registry:

```
curl http://registry:5000/v2/_catalog
```

Expected response:

```
{"repositories":[]}
```

## Dockerfile for Hello App

Application Dockerfile (located at project root) performs:
1. **Base Image**: `node:16-alpine`
2. **Working Directory**: `/app` 
3. **Copy Dependencies**: `COPY package*.json ./`
4. **Install**: `RUN npm install`
5. **Copy Rest of the Code**: `COPY . .`
6. **Expose PORT**: `EXPOSE 8080`
7. **Command**: `CMD ["npm", "start"]`

Build & tag locally:

```
docker build -t registry:5000/node-hello-app:1.0.0 .
```

Push to registry:

```
docker push registry:5000/node-hello-app:1.0.0
```

Run & verify:

```
docker run -d -p 8080:8080 --rm registry:5000/node-hello-app:1.0.0
curl http://localhost:8080/hello
```

## Jenkinsfile

The `Jenkinsfile` uses a Declarative pipeline:

- **Options**:
	- `timestamps()`, `timeout(10 MINUTES)`, `buildDiscarder(numToKeepStr: '20')`
- **Triggers**:
    - `pollSCM('H/5 * * * *')` (poll every 5 minutes)
- **Environment Variables**:
    - `DIND_CONTAINER`, `BRIDGE_NETWORK`, `REGISTRY`, `IMAGE`, `JENKINS_DOCKER_ALIAS`, `CONTAINER_PORT`, `HOST_PORT`, `TEST_CONTAINER`, `WAIT_TIME`
- **Stages**:
    1. **Pre-check Docker**: verifies the DIND container is reachable via `docker version`
    2. **Clone the Repository**: `checkout scm`
    3. **Determine Tag**: sets `VERSION` to `BUILD_NUMBER` and creates `FULL_IMAGE` name
    4. **Build, Tag & Push**: uses Docker Pipeline plugin to `docker.build` and `withRegistry(...).push()`
    5. **Tests**: spins up `ci-test` container, waits `${WAIT_TIME}`, and hits `/hello` 5 times to verify the counter
- **Post**:
    - Always clean up the test container (`docker rm -f ${TEST_CONTAINER}`)

## Issues Faced & Resolutions

- **HTTP vs HTTPS on registry**: configured `--insecure-registry` in DIND and used `docker.withRegistry("http://${REGISTRY}")` to avoid HTTPS errors.
- **DNS lookup failures**: ensured both Jenkins and registry/DIND are on the `jenkins` network with aliases (`docker`, `registry`).
- **Permission denied on Docker socket**: switched to DIND approach to isolate and avoided host socket binds.
- **Orphaned test containers**: added `post { always { rm -f ci-test } }` to clean up reliably.
- **Version tagging**: moved from `:latest` to `${BUILD_NUMBER}` for unique, immutable tags.

