#!/usr/bin/env bash
set -euxo pipefail

action="${INPUT_ACTION?}"
pkgname="${INPUT_PKGNAME?}"
ssh_private_key="${INPUT_AUR_SSH_PRIVATE_KEY?}"
git_email="${INPUT_AUR_EMAIL?}"
git_username="${INPUT_AUR_USERNAME?}"

function group() {
  echo ::group::"$*"
}
alias endgroup="echo ::endgroup::"

case "$action" in
  "validate")
    push=false
    ;;
  "publish")
    push=true
    ;;
  *)
    echo "Invalid action: $action, can only be 'validate' or 'publish'"
    exit 1
    ;;
esac

group Updating archlinux-keyring
sudo pacman -S --noconfirm archlinux-keyring
endgroup

group Configuring SSH
ssh-keyscan -v aur.archlinux.org | tee -a "$HOME/.ssh/known_hosts"
echo "$ssh_private_key" >"$HOME/.ssh/aur"
chmod -v 0600 "$HOME/.ssh/aur"
ssh-keygen -vy -f "$HOME/.ssh/aur" | tee -a "$HOME/.ssh/aur.pub"
endgroup

group Configuring GIT
git config --global user.name "$git_username"
git config --global user.email "$git_email"
endgroup

group Cloning existing AUR package
git clone -v "ssh://aur@aur.archlinux.org/$pkgname.git" /tmp/local-repo
endgroup

group Copying package files
cp -v "$pkgname/*" /tmp/local-repo/
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
  git commit . -m "chore: update"
  endgroup

  group Pushing changes
  git push
  endgroup
fi
