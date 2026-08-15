#!/usr/bin/env sh
set -eux

umask 077

AGE_KEY_HOST_SOURCE=
AGE_KEY_HOST_TARGET=/etc/sops/age/keys.txt
HOST=
NIXOS_ANYWHERE_REF=github:nix-community/nixos-anywhere
TARGET_HOST=

while [ $# -gt 0 ]; do
  case $1 in
    --age-host-source)
      AGE_KEY_HOST_SOURCE=$2
      shift 2
      continue
      ;;
    --age-host-target)
      AGE_KEY_HOST_TARGET=$2
      shift 2
      continue
      ;;
    --target-host|-t)
      TARGET_HOST=$2
      shift 2
      continue
      ;;
    --)
      shift
      break
      ;;
    --*)
      break
      ;;
    *)
      HOST=$1
      shift
      break
      ;;
  esac
done

deploy() {
  if [ -n "$TARGET_HOST" ]; then
    nix run $NIXOS_ANYWHERE_REF -- --extra-files $STAGING_ROOT --flake $FLAKE --target-host $TARGET_HOST "$@"
  else
    nixos-install --no-root-passwd --flake $FLAKE "$@"
  fi
}

init_staging_root() {
  if [ -n "$TARGET_HOST" ]; then
    STAGING_ROOT=$(mktemp --directory)
    chmod 700 $STAGING_ROOT

    trap 'rm --recursive --force $STAGING_ROOT' EXIT
  else
    STAGING_ROOT=/mnt
  fi
}

stage_age_key() {
  if [ -n "$AGE_KEY_HOST_SOURCE" ]; then
    dest_path=$STAGING_ROOT$AGE_KEY_HOST_TARGET
    dest_dir=$(dirname $dest_path)

    install --directory --mode=700 $dest_dir
    install --mode=600 $AGE_KEY_HOST_SOURCE $dest_path
  fi
}

cd "$(dirname "$0")"

FLAKE=.#$HOST

init_staging_root
stage_age_key
deploy "$@"
