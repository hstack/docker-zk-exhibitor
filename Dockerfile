FROM anapsix/alpine-java:jdk8
MAINTAINER Adrian Muraru amuraru@adobe.com

ENV \
    ZK_RELEASE="http://archive.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz" \
    EXHIBITOR_POM="https://raw.githubusercontent.com/Netflix/exhibitor/44905c15/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml"

# Use one step so we can remove intermediate dependencies and minimize size
RUN \
    # Install maven
    wget -O /opt/apache-maven.zip 'http://www.us.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.zip' \
    && unzip -d /opt/ /opt/apache-maven.zip \
    && ln -s /opt/apache-maven-3.3.9 /opt/maven \
    && ln -s /opt/maven/bin/mvn /usr/bin \

    # Install ZK
    && wget -O /tmp/zookeeper.tgz $ZK_RELEASE \
    && tar -xzf /tmp/zookeeper.tgz -C /opt/ \
    && ln -s /opt/zookeeper-* /opt/zookeeper \
    && mkdir -p /opt/zookeeper/transactions /opt/zookeeper/snapshots \
    && rm /tmp/zookeeper.tgz \

    # Install Exhibitor
    && mkdir -p /opt/exhibitor \
    && wget -O /opt/exhibitor/pom.xml $EXHIBITOR_POM \
    && mvn -f /opt/exhibitor/pom.xml package \
    && ln -s /opt/exhibitor/target/exhibitor*jar /opt/exhibitor/exhibitor.jar \

    # Remove build-time dependencies
    && rm -rf /opt/*maven* ~/.m2

# Add the wrapper script to setup configs and exec exhibitor
ADD include/wrapper.sh /opt/exhibitor/wrapper.sh

# Add the optional web.xml for authentication
ADD include/web.xml /opt/exhibitor/web.xml

USER root
WORKDIR /opt/exhibitor
EXPOSE 2181 2888 3888 8181

ENTRYPOINT ["bash", "-ex", "/opt/exhibitor/wrapper.sh"]
