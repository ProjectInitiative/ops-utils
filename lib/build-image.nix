{ pkgs }:
pkgs.writeShellScriptBin "build-image" ''
  set -e
  FLAKE_REF=$1
  if [ -z "$FLAKE_REF" ]; then
    echo "Usage: build-image <flake-ref>"
    echo "Example: build-image .#packages.x86_64-linux.my-package"
    exit 1
  fi
  
  echo "Building image from $FLAKE_REF..."
  nix build "$FLAKE_REF" -o result-image
  
  echo "Loading into Docker..."
  docker load < result-image
  rm result-image
  echo "✅ Image ready!"
''
