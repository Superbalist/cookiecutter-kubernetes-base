#!/usr/bin/env bash
#
# Installs prerequisites for the project

set -efu
set -o pipefail

MINIKUBE_VERSION="0.19.1"

if [[ "$(uname -s)" == 'Linux' ]]; then
  CLIENT_OS='Linux'
  echo "Updating aptitude, so we don't need to do this later..."
  sudo apt-get update
else
  CLIENT_OS='Darwin'
  if ! which brew &> /dev/null; then
    echo 'Installing Brew...'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  echo "Updating brew, so we don't need to do this later."
  brew update
fi

if ! which pip3 &> /dev/null; then
  echo 'Installing Python 3'
  if [[ "${CLIENT_OS}" = 'Darwin' ]]; then
    brew install python3
  else
    sudo apt-get install -y python3 python3-pip
  fi
fi

if ! which git &> /dev/null; then
  echo 'Installing Git...'
  if [[ "${CLIENT_OS}" == 'Darwin' ]]; then
    brew install git
  else
    sudo apt-get install -y git
  fi
fi

if ! which docker &> /dev/null; then
  echo 'Installing Docker...'
  if [[ "${CLIENT_OS}" = 'Darwin' ]]; then
    brew install docker
    brew link --overwrite docker
  else
    curl -sSL https://get.docker.com/ | bash -
  fi
fi

function install_minikube () {
  if [[ "${CLIENT_OS}" == 'Darwin' ]]; then
    curl -Lo minikube "https://storage.googleapis.com/minikube/releases/v${MINIKUBE_VERSION}/minikube-darwin-amd64"
  else
    curl -Lo minikube "https://storage.googleapis.com/minikube/releases/v${MINIKUBE_VERSION}/minikube-linux-amd64"
  fi
  chmod +x minikube
  sudo mv minikube /usr/local/bin/
}

if ! which minikube &> /dev/null; then
  echo 'Installing minikube'
  install_minikube
else
  INSTALLED_MINIKUBE=$(minikube version | cut -d 'v' -f 3)
  if [[ "${INSTALLED_MINIKUBE}" != "${MINIKUBE_VERSION}" ]]; then
    echo 'Upgrading minikube'
    install_minikube
  fi
fi

if ! which gcloud &> /dev/null; then
  echo 'Installing Gcloud SDK...'
  if [[ "${CLIENT_OS}" == 'Darwin' ]]; then
    curl -Lo /tmp/google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-122.0.0-darwin-x86_64.tar.gz
  else
    curl -Lo /tmp/google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-122.0.0-linux-x86_64.tar.gz
  fi
  tar xzvf /tmp/google-cloud-sdk.tar.gz
  mv google-cloud-sdk ~/google-cloud-sdk/
  ~/google-cloud-sdk/install.sh --additional-components kubectl
  echo 'Installed gcloud and added its path and completions in your bash profile.'
  if [[ "${CLIENT_OS}" == 'Darwin' ]]; then
    # Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
    # shellcheck disable=SC1091,SC1090
    . ~/.bash_profile
  else
    # Disabling this shellcheck. See https://github.com/koalaman/shellcheck/issues/769
    # shellcheck disable=SC1091,SC1090
    . ~/.bashrc
  fi
  echo 'Reloaded bash profile'
fi

echo 'Updating gcloud SDK'
gcloud components update

if ! which kubectl &> /dev/null; then
  echo 'Kubectl not installed or not in your path. Trying to install.'
  gcloud components install kubectl
fi

if ! which jinja2 &> /dev/null; then
  echo 'Installing Jinja2 CLI and PyYAML'
  python3 -m pip install jinja2-cli pyyaml
fi

if ! which hostess &> /dev/null; then
  echo 'Hostess not installed.'
  if [[ "${CLIENT_OS}" == 'Darwin' ]]; then
    brew install hostess
  else
    curl -Lo hostess "https://github.com/cbednarski/hostess/releases/download/v0.2.0/hostess_linux_amd64"
    chmod +x hostess
    sudo mv hostess /usr/local/bin/
  fi
fi

if minikube status | grep -q Stopped; then
  echo "Make sure you 'make up' to setup your local Kubernetes cluster before getting started."
else
  echo 'Minikube is running.'
  echo
  echo "You'll need to run the following before interacting with Docker:"
  echo "    eval \$(minikube docker-env)"
  echo
fi
