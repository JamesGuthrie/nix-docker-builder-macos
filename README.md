# Nix docker builder macos

This set of scripts helps to set up a docker-based remote builder for Nix.

If you want to build NixOS from your mac and deploy onto targets like a
Raspberry Pi, this could be useful.

Note: At the moment, this setup doesn't specifically set up builders for
different target architectures. If you're deploying from an M1 Mac to aarch64,
this will work fine, but it will not work if you want to deploy to x86_64. This
is not an inherent limitation, it just hasn't been done.

## Start docker container

To get the docker container started, run `make all`. This will create a new ssh
client key and host key in the `keys` directory, build a docker image with the
public component of the client key, and the host key, and start the container
listening on port 3022.

## Ensure ssh connectivity

Ensure that you can connect to the builder via ssh. The following two commands
must succeed:
- `ssh builder`
- `sudo ssh builder`

If you're using `nix-darwin` with `home-manager`, set the following in
`darwin-configuration.nix`:

```nix
  home-manager.users.<your user> = { pkgs, ... }: {
    programs.ssh = {
      enable = true;
      matchBlocks = {
       builder = {
          hostname = "127.0.0.1";
          user = "root";
          port = 3022;
          identityFile = "<path to this repo>/keys/id_ed25519";
          extraOptions = {
            "StrictHostKeyChecking" = "no";
          };
        };
      };
    };
  };

  environment.etc."ssh/ssh_config".text = ''
    Host *
      SendEnv LANG LC_*

    Host builder
      HostName 127.0.0.1
      Port 3022
      User root
      IdentityFile <path to this repo>/keys/id_ed25519
  '';
```

Now attempt to connect via SSH, and accept the host key of the builder.

## Configure remote builders

Add the following to your `darwin-configuration.nix`:
```nix
  nix = {
    distributedBuilds = true;
    buildMachines = [{
      hostName = "builder";
      system = "aarch64-linux";
      maxJobs = 10;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }];
  };
```

Ensure that the builder is reachable from your machine by running the following
commands:

- `nix store ping --store ssh://builder`
- `sudo nix store ping --store ssh://builder`

With this configuration in place, your builds for foreign architectures should
be distributed to docker.
