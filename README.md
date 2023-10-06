# Kubernetes on Equinix Metal using Nix(OS)

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

This is an experiment (that will probably yield a blog post at some point) to run Kubernetes on top of Equinix Metal using Nix and NixOS.

The motivation behind this experiment stems from our need to run a Kubernetes cluster for [Dex](https://dexidp.io/).
Dex is a CNCF project and fortunately, the CNCF provides lab resources (courtesy of Equinix Metal).

Although this is not a production use case, I'd like to minimize the maintenance cost of running a Kubernetes cluster,
hence Nix is added to the stack. Once more, we're fortunate that Equinix Metal supports running NixOS.

## Prerequisites

- [Nix](https://nixos.org/download.html) (with [Flakes](https://nixos.wiki/wiki/Flakes) support)
- [direnv](https://direnv.net/docs/installation.html)
- [Equinix Metal](https://deploy.equinix.com/) account (If you are a CNCF project maintainer, you can get one [here](https://github.com/cncf/cluster))
- [nix-direnv](https://github.com/nix-community/nix-direnv) _(optional)_

## Set up

Clone this repository:

```shell
git clone git@github.com:sagikazarmark/equi-nix-k8s.git
cd equi-nix-k8s
direnv allow
```

Run `metal init` and follow the instructions on screen to set up access to Equinix Metal from your shell.

Alternatively, copy your existing configuration to the project:

```shell
mkdir -p $(dirname $METAL_CONFIG)
cp $HOME/.config/equinix/metal.yaml $METAL_CONFIG
```

Last, but not least: you can create a `.env` file and set environment variables:

```shell
echo "METAL_ORGANIZATION_ID=253e9cf1-5b3d-41f5-a4fa-839c130c8c1d >> .env"
echo "METAL_PROJECT_ID=1857dc19-76a5-4589-a9b6-adb729a7d18b >> .env"
echo "METAL_AUTH_TOKEN=foo >> .env"
```

> [!WARNING]
> The Metal CLI does not currently accept the `METAL_CONFIG` env var in any commands other than `metal init`
> and requires passing the `--config $METAL_CONFIG` flag.
>
> Therefore I _recommend_ setting environment variables.
>
> More details [here](https://github.com/equinix/metal-cli/issues/360).

## Create an SSH key

When setting up for using Equinix Metal for the first time, create an SSH key so you can log into machines you create.

Create a new SSH key (if necessary):

```shell
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Upload the public key to Equinix Metal:

```shell
metal ssh-key create --key "$(cat ~/.ssh/id_ed25519.pub)" --label "$(hostname -s)"
```

## Launch a machine using NixOS

First, we need to determine a few parameters:

- OS version
- Region (or "metro")
- Instance type (or "plan")

> [!NOTE]
> You can familiarize yourself with the available options on the following links:
>
>   - https://deploy.equinix.com/locations/
>   - https://deploy.equinix.com/developers/capacity-dashboard/
>   - https://deploy.equinix.com/developers/os-compatibility/


The OS will also determine the list of instance types we can use, so we start with that:

```shell
metal os get --output json | jq '.[] | select(.distro == "nixos")'
```

> [!NOTE]
> At the time of this writing the latest supported NixOS version is 23.05.

We need the list of instance types from that output (`provisionable_on`) field:

```shell
metal os get --output json | jq '.[] | select(.distro == "nixos" and .version == "23.05").provisionable_on'
```

Make sure to take note of the `slug` as well:

```shell
metal os get --output json | jq '.[] | select(.distro == "nixos" and .version == "23.05").slug'
```

> [!NOTE]
> You can find the available instance types compatible with the selected OS version [here](https://deploy.equinix.com/developers/os-compatibility/).

Next, we need a location where we intend to run the new instance.
Get a list of facilities with the following command:

```shell
metal metro get
```

I'm going to use **Frankfurt** (`fr`) because it's the closes to me, but the remaining commands will use the `METAL_FACILITY` env var:

```shell
echo "METAL_METRO=fr" >> .env
```

> [!NOTE]
> You can check the [Capacity dashboard](https://deploy.equinix.com/developers/capacity-dashboard/) to see if the selected instance type is available in the chosen facility.

Once you have all the necessary details, you can launch your first instance:

```shell
metal device create --metro $METAL_METRO --operating-system nixos_23_05 --plan m3.small.x86 --hostname nixos-test
```

Take not of the UUID of your instance, but you can always get it by listing the running instances:

```shell
metal device list
```

## Cleanup

Once you are done with testing an instance, you can delete it by running the following command:

```shell
metal device delete --force --id UUID
```

## References

- https://deploy.equinix.com/labs/metal-cli/
- https://deploy.equinix.com/locations/
- https://deploy.equinix.com/developers/capacity-dashboard/
- https://deploy.equinix.com/developers/os-compatibility/
