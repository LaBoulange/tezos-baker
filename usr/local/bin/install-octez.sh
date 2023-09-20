#!/bin/bash 

. `which tezos-env.sh`

ARCHIVE=$(basename "$OCTEZ_DOWNLOAD_URL")

mkdir $BUILD_DIR
cd $BUILD_DIR

wget $OCTEZ_DOWNLOAD_URL
gunzip $ARCHIVE

ARCHIVE=${ARCHIVE::-3}

tar -xvf $ARCHIVE
rm $ARCHIVE

mv octez-client ${INSTALL_DIR}
mv octez-node ${INSTALL_DIR}
mv octez-baker-* ${INSTALL_DIR}
mv octez-accuser-* ${INSTALL_DIR}

cd /
rm -rf $BUILD_DIR

for executable in `find ${INSTALL_DIR} | grep octez`
do
  touch $executable
  chown root:root $executable
  chmod u+rwx $executable
  chmod go-rwx $executable
done
chmod go+rx ${INSTALL_DIR}/octez-client
