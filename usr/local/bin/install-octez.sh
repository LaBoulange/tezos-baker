#!/bin/bash 

. `which tezos-env.sh`

ARCHIVE='package.tar.gz'
EXTRACTED_DIR='octez-x86_64'


mkdir $BUILD_DIR
cd $BUILD_DIR

wget -O $ARCHIVE $OCTEZ_DOWNLOAD_URL
gunzip $ARCHIVE

ARCHIVE=${ARCHIVE::-3}

tar -xvf $ARCHIVE
rm $ARCHIVE

cd $EXTRACTED_DIR

mv octez-client ${INSTALL_DIR}
mv octez-node ${INSTALL_DIR}
mv octez-baker-* ${INSTALL_DIR}
mv octez-accuser-* ${INSTALL_DIR}

cd /
rm -rf $BUILD_DIR

INSTALL_USER=`whoami`
INSTALL_GROUP=`groups | awk '{print $1}'`

for executable in `find ${INSTALL_DIR} | grep octez`
do
  chown $INSTALL_USER:$INSTALL_GROUP $executable
  chmod u+rwx $executable
  chmod go-rwx $executable
done
chmod go+rx ${INSTALL_DIR}/octez-client
