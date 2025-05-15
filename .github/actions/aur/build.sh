#!/usr/bin/env bash
[[ "$RUNNER_DEBUG" == 1 ]] && set -x

set -euo pipefail

action="${INPUT_ACTION?}"
pkgname="${INPUT_PKGNAME?}"
git_email="${INPUT_AUR_EMAIL?}"
git_username="${INPUT_AUR_USERNAME?}"

function group() {
  echo ::group::"$*"
}
function endgroup() {
  echo ::endgroup::
}

case "$action" in
  "validate")
    push=false
    ;;
  "publish")
    push=true
    ssh_private_key="${INPUT_AUR_SSH_PRIVATE_KEY?}"
    ;;
  *)
    echo "Invalid action: $action, can only be 'validate' or 'publish'"
    exit 1
    ;;
esac

group Updating archlinux-keyring
sudo pacman -S --noconfirm archlinux-keyring
endgroup

if [[ -v ssh_private_key ]]; then
  group Configuring SSH
  ssh-keyscan -v aur.archlinux.org | tee -a "$HOME/.ssh/known_hosts"
  echo "$ssh_private_key" >"$HOME/.ssh/id_ed25519"
  chmod -v 0600 "$HOME/.ssh/id_ed25519"
  endgroup
fi

group Configuring GIT
git config --global user.name "$git_username"
git config --global user.email "$git_email"
endgroup

group Cloning existing AUR package
url=aur.archlinux.org/$pkgname.git
if [[ -v ssh_private_key ]]; then
  git clone -v "ssh://aur@$url" /tmp/local-repo
else
  git clone -v "https://$url" /tmp/local-repo
fi
endgroup

group Copying package files
rsync -Cav --delete "$pkgname/" /tmp/local-repo/
endgroup

cd /tmp/local-repo

if grep -q source= PKGBUILD; then
  group Updating checksums
  updpkgsums
  git diff PKGBUILD
  endgroup
fi

group Testing PKGBUILD
PACMAN="paru" PACMAN_AUTH="eval" makepkg -fs --noconfirm
endgroup

group Generating .SRCINFO
makepkg --printsrcinfo | tee .SRCINFO
endgroup

if [[ "$push" == true ]] && git diff-index -q HEAD; then
  group Committing changes
  git commit . -m "chore: sync from github"
  endgroup

  group Pushing changes
  git push
  endgroup
fi
