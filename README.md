kafka-deb-packaging
===================

Simple debian packaging for Apache Kafka

__requires fpm ruby gem:__
> sudo apt-get install rubygems

> sudo gem install fpm

Works for our purposes, namely building from our Kafka 0.8/Scala 2.10 fork:
> build_kafka.sh -v 0.8 -g https://github.com/victorops/kafka.git -s 2.10.1
