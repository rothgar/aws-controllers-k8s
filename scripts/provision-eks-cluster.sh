#!/usr/bin/env bash

# A script that provisions an EKS Kubernetes cluster for testing

set -Eo pipefail

SCRIPTS_DIR=$(
  cd "$(dirname "$0")"
  pwd
)
ROOT_DIR="$SCRIPTS_DIR/.."

source "$SCRIPTS_DIR"/lib/common.sh
source "$SCRIPTS_DIR"/lib/k8s.sh
source "$SCRIPTS_DIR"/lib/helm.sh
source "$SCRIPTS_DIR"/lib/eks.sh

SCRIPT_PATH="$(
  cd "$(dirname "$0")"
  pwd -P
)"
PLATFORM=$(uname | tr '[:upper:]' '[:lower:]')
TEST_ID=$(uuidgen | cut -d'-' -f1 | tr '[:upper:]' '[:lower:]')
CLUSTER_NAME_BASE=$(uuidgen | cut -d'-' -f1 | tr '[:upper:]' '[:lower:]')

K8_VERSION="${1:-1.17}"

echoerr() { echo "$@" 1>&2; }

USAGE="
Usage:
  $(basename "$0") [-b TEST_BASE_NAME] [-v K8s_VERSION]

Provisions an EKS cluster for testing. Outputs the directory containing the kubectl
cluster context to stdout on successful completion

Example: $(basename "$0") -b my-test -v 1.16

  Optional:
      -c      Existing cluster name
      -b      Base Name of cluster
      -v      K8s version to use in this test
      -k      EKS cluster config file
      -h      Show help
"

# Process our input arguments
while getopts "c:b:v:k:h" opt; do
  case ${opt} in
  c) # Existing Cluster Name
    EXISTING_CLUSTER_NAME=${OPTARG}
    ;;
  b) # BASE CLUSTER NAME
    CLUSTER_NAME_BASE=${OPTARG}
    ;;
  v) # K8s version to provision
    K8_VERSION=${OPTARG}
    ;;
  k) # EKS cluster config file
    EKS_CONFIG_FILE="${OPTARG}"
    ;;
  \? | h)
    echoerr "${USAGE}" 1>&2
    exit
    ;;
  esac
done

check_is_installed docker

ensure_eksctl
ensure_kubectl
ensure_helm

CLUSTER_NAME="${EXISTING_CLUSTER_NAME:-$CLUSTER_NAME_BASE-$TEST_ID}"
TMP_DIR=$ROOT_DIR/build/tmp-$CLUSTER_NAME

echoerr "Using Kubernetes $K8_VERSION"
mkdir -p "${TMP_DIR}"

if [[ -z $(eksctl get cluster --name $CLUSTER_NAME >& $TMP_DIR/provision.log) ]]; then
	echoerr "Creating k8s cluster using eksctl..."
	echoerr "This might take a while. tail -f $TMP_DIR/provision.log"
  eksctl create cluster --name "$CLUSTER_NAME" --version $K8_VERSION \
    --fargate --kubeconfig ${TMP_DIR}/kubeconfig --color false >& $TMP_DIR/provision.log \
	|| exit 1
else
  echo "Cluster ${CLUSTER_NAME} already exists"
fi

echo "$CLUSTER_NAME" > $TMP_DIR/clustername
echo $TMP_DIR
