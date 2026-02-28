#!/bin/bash 

. `which tezos-env.sh`

ARCHIVE='tezos.baker.tar.gz'

INSTALL_USER=`whoami`
INSTALL_GROUP=`groups | awk '{print $1}'`

# Function to display usage message
show_usage() {
    echo "Usage: $0 [--branch BRANCH_NAME]"
    echo "  --branch: Specify a branch to install from (default: latest release)"
    exit 1
}

# Parse command line arguments
BRANCH=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            if [ -z "$2" ] || [[ "$2" == --* ]]; then
                show_usage
            fi
            BRANCH="$2"
            shift 2
            ;;
        *)
            show_usage
            ;;
    esac
done

# Determine download URL based on whether --branch was specified
if [ -n "$BRANCH" ]; then
    echo "Installing from branch: $BRANCH"
    TEZOS_BAKER_DOWNLOAD_URL="https://github.com/LaBoulange/tezos-baker/archive/refs/heads/${BRANCH}.tar.gz"
else
    echo "Installing from latest release"
    TEZOS_BAKER_DOWNLOAD_URL=`wget https://api.github.com/repos/LaBoulange/tezos-baker/releases/latest -O - | sed -nr 's/\s*"tarball_url":\s*"(.*)",/\1/p'`
fi

THIS_FILE_NAME='install-tezos-baker.sh'

mkdir $BUILD_DIR
cd $BUILD_DIR

wget $TEZOS_BAKER_DOWNLOAD_URL -O $ARCHIVE
gunzip $ARCHIVE

ARCHIVE=${ARCHIVE::-3}

tar -xvf $ARCHIVE
rm $ARCHIVE

EXTRACTED_DIR=`ls`
cd ${EXTRACTED_DIR}/usr/local/bin

# Set ownership and permissions for all executable files
chown $INSTALL_USER:$INSTALL_GROUP *.sh tezos-baker 2>/dev/null || true
chmod u+rwx *.sh tezos-baker 2>/dev/null || true
chmod go-rwx *.sh tezos-baker 2>/dev/null || true

# Move this file to a temporary location to avoid overwriting itself
mv $THIS_FILE_NAME ${INSTALL_DIR}/${THIS_FILE_NAME}.new

# Move all executable files to install directory
mv *.sh $INSTALL_DIR 2>/dev/null || true
mv tezos-baker $INSTALL_DIR 2>/dev/null || true

cd ${BUILD_DIR}/${EXTRACTED_DIR}

# Install shell completion files
SHARE_DIR="${INSTALL_DIR%/bin}/share"

BASH_COMPLETION_DIR="${SHARE_DIR}/bash-completion/completions"
mkdir -p "$BASH_COMPLETION_DIR"
if [ -f "usr/local/share/bash-completion/completions/tezos-baker" ]; then
    cp usr/local/share/bash-completion/completions/tezos-baker "$BASH_COMPLETION_DIR/tezos-baker"
    chown $INSTALL_USER:$INSTALL_GROUP "$BASH_COMPLETION_DIR/tezos-baker" 2>/dev/null || true
    chmod u+rw,go+r "$BASH_COMPLETION_DIR/tezos-baker"
fi

ZSH_COMPLETION_DIR="${SHARE_DIR}/zsh/site-functions"
mkdir -p "$ZSH_COMPLETION_DIR"
if [ -f "usr/local/share/zsh/site-functions/_tezos_baker" ]; then
    cp usr/local/share/zsh/site-functions/_tezos_baker "$ZSH_COMPLETION_DIR/_tezos_baker"
    chown $INSTALL_USER:$INSTALL_GROUP "$ZSH_COMPLETION_DIR/_tezos_baker" 2>/dev/null || true
    chmod u+rw,go+r "$ZSH_COMPLETION_DIR/_tezos_baker"
fi

cd /
rm -rf $BUILD_DIR

(sleep 2 ; mv ${INSTALL_DIR}/${THIS_FILE_NAME}.new ${INSTALL_DIR}/${THIS_FILE_NAME}) &
