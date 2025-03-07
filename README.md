# IBM Garage command-line tools

[![Docker Repository on Quay](https://quay.io/repository/ibmgaragecloud/cli-tools/status "Docker Repository on Quay")](https://quay.io/repository/ibmgaragecloud/cli-tools)

This repository builds a Docker image whose container is a client for using IBM Cloud.

The container includes the following tools - (tool@version):
- terraform cli@0.12.23
- terraform plugins:
  - terraform-provider-helm@1.0.0
  - terraform-provider-kube@1.10.0
  - terraform-provider-ibm@1.2.3
  - terraform-provider-ibm@1.2.2
  - terraform-provider-ibm@1.2.1
- calico cli@3.12.0
- ibmcloud cli
- ibmcloud plugins:
  - container-service
  - container-registry
  - cloud-databases
- kubectl cli@1.15.5
- kustomize cli
- openshift (oc) cli 
- helm2 cli
- helm3 cli
- git cli
- nvm cli@0.35.2
- node cli@12.x
- npm cli
- solsa cli@0.3.5
- yeoman (yo) cli

The container also includes the following helper scripts:
- init.sh
- createNamespaces.sh
- installHelm.sh
- cluster-pull-secret-apply.sh
- setup-namespace-pull-secrets.sh
- checkPodRunning.sh
- copy-secret-to-namespace.sh

**Warning: The material contained in this repository has not been thoroughly tested. Proceed with caution.**

## Getting started

### Prerequisites

To run this image, the following tools are required:

- `Docker` - kinda obvious, but since we are running a Docker image, you need to have the tool available

### Running the client

Start the client to use it.

- To run the `icclient` container:

    ```bash
    docker run -itd --name icclient ibmgaragecloud/cli-tools
    ```

    This  assumes the image's default name, `ibm-garage-cli-tools`.

Once the client is running in the backgroud, use it by opening a shell into it.

- To use the `icclient` container, exec shell into it:

    ```bash
    docker exec -it icclient /bin/bash
    ```

    Your terminal is now in the container. 

Use this shell to run commands using the installed tools and scripts.

When you're finished running commands, to exit the client.

- To leave the `icclient` container shell, as with any shell:

    ```bash
    exit
    ```

    The container will keep running after you exit its shell.

If the client stops:

- To run the `icclient` container again:

    ```bash
    docker start icclient
    ```

The `icclient` container is just a Docker container, so all [Docker CLI commands](https://docs.docker.com/engine/reference/commandline/cli/) work.

### Using the client

From a client shell, run `image-help` to get a list of available tools, scripts, and ENV properties:

```bash
$ image-help
Available env properties (can be overridden for individual commands):
 > BM_API_KEY - the IBM Cloud api key
 > REGION - the IBM Cloud region (e.g. us-south)
 > RESOURCE_GROUP - the IBM Cloud resource group
 > CLUSTER_NAME - the name of the kubernetes cluster in IBM Cloud
 > SL_USERNAME - the Classic Infrastructure user name or API user name (e.g. 282165_joe@us.ibm.com)
 > SL_API_KEY - the Classic Infrastructure api key

Available tools:
 > terraform (with helm, kube, and ibm provider plugins)
 > calicoctl
 > ibmcloud (with container-service, container-registry, and cloud-databases plugins)
 > kubectl
 > kustomize
 > oc
 > helm
 > docker
 > git
 > nvm
 > node (v11.12.0 currently installed)
 > solsa
 > yo

Available scripts:
 > init.sh {BM_API_KEY} {REGION} {RESOURCE_GROUP} {CLUSTER_NAME}
 > createNamespaces.sh
 > deleteNamespace.sh
 > installHelm.sh
 > cluster-pull-secret-apply.sh
 > setup-namespace-pull-secrets.sh
 > checkPodRunning.sh
 > copy-secret-to-namespace.sh
```

## Development

### Prerequisites

To use/build this image, the following tools are required:

- `Docker` - kinda obvious, but since we are building, testing and running a Docker image, you need to have
the tool available
- `node/npm` - (optional) used to consolidate the configuration and scripts for working with the image, it
is **highly** recommended that `npm` is used; however, it is possible to run the scripts directly by looking
at `package.json` and providing the appropriate values

### Using the image

To use the image, a local image of the tool is required. You can get the image either by pulling from Docker Hub or 
building locally:

```bash
npm run pull
```

**OR**

```bash
npm run build
```

After that, start the image in an interactive terminal with:

```bash
npm start
```

### File Layout

- `package.json` - scripts and config for the image build
- `Dockerfile` - the docker image definition
- `config.yaml` - the test config file for the `container-structure-test` tool
- `scripts/` - directory for shell scripts used by `package.json` scripts to build, test, and 
push the image
- `src/` - directory containing files that should be included in the built image

### Commands

The following commands should be used when developing the docker image. They use scripts
provided in the `scripts/` folder.

#### Build the image

```bash
npm run build
```

This will build the image locally with the tag `IMAGE_NAME`:`IMAGE_VERSION`.

#### Test the image

```bash
npm test
```

This will build the image locally, if necessary, and validate the elements of the
image.

The tests use Google's `container-structure-test` to validate the structure of 
the image. Configuration for these tests are provided in the aptly named `config.yaml`.

See https://github.com/GoogleContainerTools/container-structure-test for information on the
defined values for the test definition.

#### Releasing the a version to Docker Hub

A build pipeline is configured in Docker Hub to create new image versions when a change is pushed to Git. A new `latest` tag will be put on the tip of `master` branch and a
versioned image tag will be created off of Git tags.

In order to release a new version of the code for build, run the following:

```bash
export GITHUB_TOKEN="<github PAT>"
npm run release
```

...and follow the on screen instructions

**Note:** The GITHUB_TOKEN should be your personal access token for GitHub. It is needed in order to create the `release` documentation in the repo

#### Configuration

These scripts require parameters for:
- `IMAGE_ORG` 
- `IMAGE_NAME`
- `IMAGE_VERSION`

When the scripts are run using `npm` (recommended) then these parameters are provided from
config values in `package.json`:
- `org`
- `name`
- `version`

The default/preferred `org` for the image is `garagecatalyst`. If you need access to the
org in Docker Hub contact Matt Perrins (mjperrin@us.ibm.com) or Sean Sundberg 
(seansund@us.ibm.com).
