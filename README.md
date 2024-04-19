# install

Edgebox Installation Script for Debian/Ubuntu.

This script will install the Edgebox software on a Debian/Ubuntu system. It will install the necessary dependencies, download the Edgebox software, and configure the system to run it automatically.

## Requirements

- A working Debian 10 or newer / Ubuntu 22.04 or newer system

ℹ️ Looking for a different platform? Edgebox runs on MacOS, Windows, and other Linux distributions through our [Multipass setup repository](https://github.com/edgebox-iot/multipass-setup).

## Installation

```bash
curl -sSL install.edgebox.io | sudo bash -s -- --system-password <password>
```

Replace `<password>` with the password you want to use for the system user `edgebox`.
More flags can be passed to the script. Below is a list of all available flags and their default values.

### Flags

There are two categories of flags that can be passed to the script: skip flags and configuration flags.

#### Skip Flags

```bash
--no-update-apt              # Do not update system packages

--no-install-deps            # Do not install Edgebox dependencies
--no-install-avahi           # Do not install Avahi
--no-install-yq              # Do not install yq
--no-install-docker          # Do not install Docker
--no-install-compose         # Do not install Docker Compose
--no-install-cloudflared     # Do not install Cloudflared
--no-install-sshx            # Do not install SSHX

--no-install-components      # Do not install Edgebox components
--no-install-edgeboxctl      # Do not install Edgeboxctl
--no-install-edgebox-api     # Do not install Edgebox API
--no-install-edgebox-apps    # Do not install Edgebox Apps
--no-install-edgebox-logger  # Do not install Edgebox Logger
--no-install-edgebox-updater # Do not install Edgebox Updater

--no-create-user             # Do not create the system user
--no-add-motd                # Do not add the Edgebox MOTD to the system prompt
--no-auto-start              # Do not start the Edgebox services automatically
```

#### Configuration Flags

```bash
--system-password <password> # Password for the system user
--install-path <path>        # Path to install Edgebox components
--cluster-host <name>        # Public Hostname of the Edgebox cluster (for load balancer support configuration)
-- version <version>         # Version of Edgebox to install (default: latest)
```


Further information can be found on the [Edgebox Documentation](https://docs.edgebox.com).

