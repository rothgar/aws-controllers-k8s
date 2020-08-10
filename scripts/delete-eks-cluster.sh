#!/bin/bash
set -eo pipefail

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

USAGE=$(cat << 'EOM'
  Usage: delete-cluster  [-c <CLUSTER_CONTEXT>] [-o]
  Deletes a EKS cluster and context dir
  Example: delete-cluster -c build/tmp-cluster-1234
          Required:
            -c          Cluster context directory
          Optional:
            -o          Override path w/ your own kubectl and EKS binaries
EOM
)

# Process our input arguments
while getopts "c:o" opt; do
  case ${opt} in
    c ) # Cluster context directory
        TMP_DIR=$OPTARG
        CLUSTER_NAME=$(cat $TMP_DIR/clustername)
      ;;
    o ) # Override path with your own kubectl and EKS binaries
	      OVERRIDE_PATH=1
        export PATH=$PATH:$TMP_DIR
      ;;
    \? )
        echoerr "$USAGE" 1>&2
        exit
      ;;
  esac
done

echo "🥑 Deleting k8s cluster using \"eks\""
eksctl delete cluster --name "$CLUSTER_NAME"
rm -r $TMP_DIR
