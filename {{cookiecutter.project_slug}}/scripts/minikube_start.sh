#!/usr/bin/env bash
#
# Configure and start minikube and mount /Users or /home in minikube

set -efu
set -o pipefail

if [[ "$(uname -s)" = 'Linux' ]]; then
  CLIENT_OS='Linux'
else
  CLIENT_OS='Darwin'
fi

################################################
# Function to disable Virtio9p on OSX
# Return:
#   None
################################################
handle_dodgy_virtio () {
  echo "Disabling Virtio9p mounting of /Users dir and starting minikube again"
  sed -i"" -e '/"Virtio9p"/ s/true/false/'  ~/.minikube/machines/minikube/config.json
  minikube stop
  minikube start
}

if echo "$(minikube status)" | head -1 | grep -q -v "Stopped\|Running"; then
  echo 'No Minikube VM found.'
  echo "Creating minikube VM..."
  if [[ "${CLIENT_OS}" == 'Darwin' ]]; then
    echo "(Using the xhyve driver)"
    set +e
    # First install exit(1)'s FNAR
    brew install docker-machine-driver-xhyve
    set -e
    sudo chown root:wheel "$(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve"
    sudo chmod u+s "$(brew --prefix)/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve"
    echo "/Users -network 192.168.64.0 -mask 255.255.255.0 -alldirs -maproot=root:wheel" | sudo tee -a /etc/exports
    sudo nfsd restart
    minikube start --memory=3072 --cpus=1 --vm-driver=xhyve || handle_dodgy_virtio
  else
    sudo apt-get update
    sudo apt-get install libvirt-bin qemu-kvm nfs-kernel-server
    sudo curl -L https://github.com/dhiltgen/docker-machine-kvm/releases/download/v0.7.0/docker-machine-driver-kvm -o /usr/local/bin/docker-machine-driver-kvm
    sudo chmod +x /usr/local/bin/docker-machine-driver-kvm
    echo "/home       192.168.0.0/255.255.0.0(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
    sudo systemctl restart nfs-kernel-server && sleep 5
    minikube start --memory=3072 --cpus=1 --vm-driver=kvm
  fi
elif minikube status | grep -q 'Stopped'; then
  echo 'Starting minikube.'
  minikube start || handle_dodgy_virtio
else
  echo 'Minikube is running.'
fi

eval "$(minikube docker-env)"
if [[ "${CLIENT_OS}" = 'Darwin' ]]; then
  if ! docker info | grep "provider=xhyve"; then
    echo "Xhyve is the only supported VM driver for OSX"
    echo "It looks like you're using:"
    echo "    $(docker info | grep provider=)"
    exit 1
  fi

  echo "Starting and mounting NFS on Minikube"
  set +e
  minikube ssh -- sudo mkdir -p /Users
  if [[ "$(minikube ssh -- "grep '^NAME=' /etc/os-release | sed -e 's/NAME=//g'")" == "Boot2Docker" ]]; then
    minikube ssh -- sudo /usr/local/etc/init.d/nfs-client start
    minikube ssh -- "if [ -z \"\$(mount | grep User | grep 192.168.64.1)\" ]; then sudo mount 192.168.64.1:/Users /Users -o rw,async,noatime,rsize=32768,wsize=32768,proto=tcp; fi"
  else
    minikube ssh -- "if [ -z \"\$(mount | grep User | grep 192.168.64.1)\" ]; then sudo busybox mount -t nfs -oasync,noatime,nolock 192.168.64.1:/Users /Users; fi"
  fi
  set -e
else
  if ! docker info | grep "provider=kvm"; then
    echo "KVM is the only supported VM driver for Linux"
    echo "It looks like you're using:"
    echo "    $(docker info | grep provider=)"
    exit 1
  fi

  HOST_IP=$(ifconfig virbr1 | awk '/inet addr/{split($2,a,":"); print a[2]}')

  echo "Starting and mounting NFS on Minikube"
  set +e
  minikube ssh -- sudo mkdir -p /Users
  if [[ "$(minikube ssh -- "grep '^NAME=' /etc/os-release | sed -e 's/NAME=//g'")" == "Boot2Docker" ]]; then
    minikube ssh -- sudo /usr/local/etc/init.d/nfs-client start
    minikube ssh -- "if [ -z \"\$(mount | grep home | grep ${HOST_IP})\" ]; then sudo mount ${HOST_IP}:/home /Users -o rw,async,noatime,rsize=32768,wsize=32768,proto=tcp,nolock; fi"
  else
    minikube ssh -- "if [ -z \"\$(mount | grep home | grep ${HOST_IP})\" ]; then sudo busybox mount -t nfs -oasync,noatime,nolock ${HOST_IP}:/home /Users; fi"
  fi
  minikube ssh -- sudo ln -s "/Users/${USER}/" /home/
  set -e
fi
eval "$(minikube docker-env)"
