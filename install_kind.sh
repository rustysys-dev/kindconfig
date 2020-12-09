#!/bin/bash

### VERIFIED TO WORK ON AMAZON_LINUX_2 SHOULD WORK ON OTHER DISTRIBUTIONS PROVIDED DEPENDENCIES ARE MET.
function setup_kubernetes() {
    local kubectl_latest kubectl_url kustomize_installer kind_version_latest kind_tag_latest kind_image

    function log() {
        local GREEN NC MSG
        GREEN='\033[0;32m'
        NC='\033[0m'
        MSG="$1"
        echo -e "${GREEN}${MSG}${NC}"
    }
    
    log "### ENSUREING DEPENDENCIES ###"
    sudo yum -q -y install git docker jq
    kind_version_latest="$(git ls-remote --tags --sort="v:refname" git://github.com/kubernetes-sigs/kind.git | cut -d"/" -f3 | tail -1)"
    kind_tag_latest="$(wget -q https://registry.hub.docker.com/v1/repositories/kindest/node/tags -O - | jq -r '.[-1].name')"
    kind_image="kindest/node:${kind_tag_latest}"
    mkdir -p ~/bin

    log "### INSTALLING KUBECTL KUSTOMIZE KIND ###"
    ## KUBECTL
    kubectl_latest="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
    kubectl_url="https://storage.googleapis.com/kubernetes-release/release/${kubectl_latest}/bin/linux/amd64/kubectl"
    curl -sLo ~/bin/kubectl "${kubectl_url}" && chmod +x ~/bin/kubectl

    ## KUSTOMIZE
    kustomize_installer="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"
    (cd ~/bin && curl -s "${kustomize_installer}" | bash) && chmod +x ~/bin/kustomize

    ## KIND
    curl -sLo ~/bin/kind https://kind.sigs.k8s.io/dl/"${kind_version_latest}"/kind-linux-amd64
    chmod +x ~/bin/kind

    ## ECR ACCESS DOCKER
    log "### SETUP DOCKER ###"
    #####################################################
    ### CODE TO SETUP YOUR ~/.docker/config.json HERE ###
    ### REQUIRED FOR ACCESS TO PRIVATE REPOSITORIES   ###
    #####################################################
    cp ~/.docker/config.json ~/

    ## START KIND
    log "### STARTING KIND ###"
    wget -q https://raw.githubusercontent.com/rustysys-dev/kindconfig/main/ec2-kind-config.yaml -O kind-config.yaml
    kind create cluster --config ./kind-config.yaml --image "${kind_image}"
    kubectl wait --for=condition=ready node --all --timeout=-1s
}

setup_kubernetes
