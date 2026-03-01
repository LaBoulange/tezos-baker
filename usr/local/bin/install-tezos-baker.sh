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

# Store the absolute path to the extracted directory before any cd
EXTRACTED_ABS_DIR="${BUILD_DIR}/${EXTRACTED_DIR}"

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

# Install shell completion files
BASH_COMPLETION_DIR="/usr/share/bash-completion/completions"
ZSH_COMPLETION_DIR="/usr/local/share/zsh/site-functions"
BASH_COMPLETION_MARKER="# tezos-baker shell completion"
BASH_COMPLETION_LINE="[ -f ${BASH_COMPLETION_DIR}/tezos-baker ] && source ${BASH_COMPLETION_DIR}/tezos-baker"

BASH_COMPLETION_SRC="${EXTRACTED_ABS_DIR}/usr/local/share/bash-completion/completions/tezos-baker"
ZSH_COMPLETION_SRC="${EXTRACTED_ABS_DIR}/usr/local/share/zsh/site-functions/_tezos_baker"

# Determine what needs to be done
INSTALL_BASH_COMPLETION=false
INSTALL_ZSH_COMPLETION=false
ADD_BASHRC_LINE=false

[ -f "$BASH_COMPLETION_SRC" ] && INSTALL_BASH_COMPLETION=true
[ -f "$ZSH_COMPLETION_SRC" ] && INSTALL_ZSH_COMPLETION=true
if $INSTALL_BASH_COMPLETION && ! grep -qF "$BASH_COMPLETION_MARKER" /etc/bash.bashrc 2>/dev/null; then
    ADD_BASHRC_LINE=true
fi

# Only prompt if there is something to write
if $INSTALL_BASH_COMPLETION || $INSTALL_ZSH_COMPLETION || $ADD_BASHRC_LINE; then
    echo ""
    echo "Shell auto-completion can be installed for tezos-baker."
    echo "This will:"
    $INSTALL_BASH_COMPLETION && echo "  - Copy bash completion file to ${BASH_COMPLETION_DIR}/"
    $INSTALL_ZSH_COMPLETION  && echo "  - Copy zsh completion file to ${ZSH_COMPLETION_DIR}/"
    $ADD_BASHRC_LINE         && echo "  - Add a source line to /etc/bash.bashrc for automatic activation"
    echo ""
    read -p "Install shell completion? [Y/n]: " answer
    answer=${answer:-y}
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        # Bash completion
        if $INSTALL_BASH_COMPLETION; then
            mkdir -p "$BASH_COMPLETION_DIR"
            cp "$BASH_COMPLETION_SRC" "$BASH_COMPLETION_DIR/tezos-baker"
            chown $INSTALL_USER:$INSTALL_GROUP "$BASH_COMPLETION_DIR/tezos-baker" 2>/dev/null || true
            chmod u+rw,go+r "$BASH_COMPLETION_DIR/tezos-baker"
        fi

        # Zsh completion
        if $INSTALL_ZSH_COMPLETION; then
            mkdir -p "$ZSH_COMPLETION_DIR"
            cp "$ZSH_COMPLETION_SRC" "$ZSH_COMPLETION_DIR/_tezos_baker"
            chown $INSTALL_USER:$INSTALL_GROUP "$ZSH_COMPLETION_DIR/_tezos_baker" 2>/dev/null || true
            chmod u+rw,go+r "$ZSH_COMPLETION_DIR/_tezos_baker"
        fi

        # Add source line to /etc/bash.bashrc if needed
        if $ADD_BASHRC_LINE; then
            echo "" >> /etc/bash.bashrc
            echo "$BASH_COMPLETION_MARKER" >> /etc/bash.bashrc
            echo "$BASH_COMPLETION_LINE" >> /etc/bash.bashrc
        fi

        echo "Shell completion installed. Open a new shell session to activate it."
    else
        echo "Shell completion installation skipped."
        echo "You can activate it manually at any time:"
        echo "  eval \"\$(tezos-baker completion bash)\""
    fi
fi

cd /
rm -rf $BUILD_DIR

# Update this file after execution terminates
(sleep 2 ; mv ${INSTALL_DIR}/${THIS_FILE_NAME}.new ${INSTALL_DIR}/${THIS_FILE_NAME}) &
