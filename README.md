# ops-utils

Shared Operations Utilities for Homelab and Development Environments.

This flake provides reusable Nix functions to generate shell scripts for common operations like building container images from flakes and pushing them to registries (including multi-arch support).

## Usage

Add `ops-utils` to your `flake.nix` inputs:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  ops-utils.url = "github:projectinitiative/ops-utils";
};
```

### Quick Start (Recommended)

Use `mkUtils` to instantiate all utilities at once.

```nix
outputs = { self, nixpkgs, ops-utils }:
  let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Instantiate all tools
        ops = ops-utils.lib.mkUtils {
          inherit pkgs;
          # supportedSystems defaults to [ "x86_64-linux" "aarch64-linux" ] if omitted
        };
      in
      {
        # Your other packages...
        my-app = pkgs.hello;
      }
      # Merge the ops tools directly into your packages.
      # This automatically exposes all current and future tools from ops-utils.
      // ops
    );

    apps = forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ops = ops-utils.lib.mkUtils { inherit pkgs; };
        
        # Generate apps for all ops tools automatically
        opsApps = ops-utils.lib.mkApps { inherit pkgs; } ops;
      in
      {
        # Your other apps...
        my-app = { type = "app"; program = "..."; };
      }
      # Merge the ops apps
      // opsApps
    );
  };
```

Example usage for individiual packages:
```nix
# ... inside your outputs ...
packages = forAllSystems (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    # One call to get them all!
    ops = ops-utils.lib.mkUtils { inherit pkgs; };
  in
  {
    inherit (ops) build-image push-multi-arch push-insecure;
  }
);

apps = forAllSystems (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    ops = ops-utils.lib.mkUtils { inherit pkgs; };
    
    # Generate apps for all ops tools automatically
    opsApps = ops-utils.lib.mkApps { inherit pkgs; } ops;
  in
  {
    inherit (opsApps) build-image push-multi-arch push-insecure;
    # Your other apps...
    my-app = { type = "app"; program = "..."; };
  }
);
```

### Available Functions (Low Level)

If you prefer to instantiate tools individually, the raw functions are available under `lib`.

#### `mkGenericBuildImage`

Creates a script named `build-image` that builds a flake output and loads it into the local Docker daemon.

**Signature:** `{ pkgs } -> derivation`

**Example:**
```nix
packages.build-image = ops-utils.lib.mkGenericBuildImage { inherit pkgs; };
```

#### `mkPushMultiArch`

Creates a script named `push-multi-arch` that builds a package for multiple architectures, loads them, tags them, pushes them to a registry (e.g., GHCR), and creates a multi-arch manifest.

**Signature:** `{ pkgs, supportedSystems } -> derivation`

**Example:**
```nix
packages.push-multi-arch = ops-utils.lib.mkPushMultiArch { 
  inherit pkgs;
  supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
};
```

#### `mkPushInsecure`

Creates a script named `push-insecure` designed for pushing images to a local or insecure registry (HTTP). It builds for the current system only.

**Signature:** `{ pkgs, system } -> derivation`

**Example:**
```nix
packages.push-insecure = ops-utils.lib.mkPushInsecure { inherit pkgs system; };
```

## Development

To hack on this flake:

```bash
nix develop
```