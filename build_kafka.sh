#!/bin/bash

#
# NOTE: This is working for our specific needs; building Kafka 0.8 for Scala 2.10.1
#        I.e. "build_kafka.sh -v 0.8 -g https://github.com/victorops/kafka.git -s 2.10.1"
#
#

set -e
set -u
name=kafka
description="Apache Kafka is a distributed publish-subscribe messaging system."
url="https://kafka.apache.org/"
arch="all"
section="misc"
license="Apache Software License 2.0"
origdir="$(pwd)"

gitrepo=
scala_version=2.8.0
version=0.7.2-incubating
while getopts  "g:v:s:" flag
do
  case "$flag" in
    v) version="$OPTARG"
      ;;
    g) gitrepo="$OPTARG"
      ;;
    s) scala_version="$OPTARG"
      ;;
  esac
done

package_version="-1"
src_package="kafka-${version}-src.tgz"
download_url="http://mirrors.sonic.net/apache/incubator/kafka/kafka-${version}/${src_package}"
kafka_src_dir=kafka-${version}-src

# Do some setup.  We'll be building in 'tmp'
rm -rf ${name}*.deb
mkdir -p tmp && pushd tmp
rm -rf kafka
mkdir -p kafka
cd kafka
mkdir -p build/usr/lib/kafka
mkdir -p build/etc/default
mkdir -p build/etc/init
mkdir -p build/etc/kafka
mkdir -p build/var/log/kafka

# Either clone the given repo or download the source tarball
if [ "$gitrepo" != "" ]; then
    git clone "$gitrepo" ./${kafka_src_dir}

    # sbt is not in all repos, so copy it in from here if it's missing.
    if [ ! -e ./${kafka_src_dir}/sbt ]; then
        echo copying sbt
        cp ${origdir}/sbt/sbt ./${kafka_src_dir}/sbt
        cp ${origdir}/sbt/sbt-launch.jar ./${kafka_src_dir}/lib/sbt-launch.jar
    fi
else
    #_ MAIN _#
    if [[ ! -f "${src_package}" ]]; then
      wget -O ${origdir}/${src_package} ${download_url}
    fi
    tar zxf ${origdir}/${src_package}
fi

# Build kafka from source
cd ${kafka_src_dir}
echo sbt update
./sbt update
echo "****** Building... ******"
echo sbt \"++${scala_version} package\"
./sbt "++${scala_version} package"

# Prep for building the package; copy over the upstat scripts and so on
cp ${origdir}/kafka-broker.default ../build/etc/default/kafka-broker
cp ${origdir}/kafka-broker.upstart.conf ../build/etc/init/kafka-broker.conf
mv config/log4j.properties config/server.properties ../build/etc/kafka
mv * ../build/usr/lib/kafka
cd ../build

# Build the package; fpm is a rubygem.  Need Ruby 1.8, rubygems and "gem install fpm".
fpm -t deb \
    -n ${name} \
    -v ${version}${package_version} \
    --description "${description}" \
    --url="{$url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "" \
    --license "${license}" \
    -m "${USER}@localhost" \
    --prefix=/ \
    -s dir \
    -- .
mv kafka*.deb ${origdir}

