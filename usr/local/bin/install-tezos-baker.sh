#!/bin/bash 

. `which tezos-env.sh`

ARCHIVE='tezos.baker.tar.gz'

INSTALL_USER=`whoami`
INSTALL_GROUP=`groups | awk '{print $1}'`

TEZOS_BAKER_PROJECT="LaBoulange/tezos-baker"
TEZOS_BAKER_DOWNLOAD_URL=`wget https://api.github.com/repos/${TEZOS_BAKER_PROJECT}/releases/latest -O - | sed -nr 's/\s*"tarball_url":\s*"(.*)",/\1/p'`

THIS_FILE_NAME='update-tezos-baker.sh'


mkdir $BUILD_DIR
cd $BUILD_DIR

wget $TEZOS_BAKER_DOWNLOAD_URL -O $ARCHIVE
gunzip $ARCHIVE

ARCHIVE=${ARCHIVE::-3}

tar -xvf $ARCHIVE
rm $ARCHIVE

cd `ls`/usr/local/bin

chown $INSTALL_USER:$INSTALL_GROUP *.sh
chmod u+rwx *.sh
chmod go-rwx *.sh

mv $THIS_FILE_NAME ${INSTALL_DIR}/${THIS_FILE_NAME}.new

mv *.sh $INSTALL_DIR

cd /
rm -rf $BUILD_DIR

(sleep 2 ; mv ${INSTALL_DIR}/${THIS_FILE_NAME}.new ${INSTALL_DIR}/${THIS_FILE_NAME}) &
