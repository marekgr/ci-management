#!/bin/bash
set -xe -o pipefail

update_cmake_repo() {
    cat /etc/resolv.conf
    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
    cat /etc/resolv.conf

    CMAKE_INSTALL_SCRIPT_URL="https://cmake.org/files/v3.8/cmake-3.8.0-Linux-x86_64.sh"
    CMAKE_INSTALL_SCRIPT="/tmp/install_cmake.sh"
    curl ${CMAKE_INSTALL_SCRIPT_URL} > ${CMAKE_INSTALL_SCRIPT}

    sudo mkdir -p /opt/cmake
    sudo bash ${CMAKE_INSTALL_SCRIPT} --skip-license --prefix=/opt/cmake
    export PATH=/opt/cmake/bin:$PATH
}

cd libparc

[ "$DOCS_REPO_URL" ] || DOCS_REPO_URL="https://nexus.fd.io/content/sites/site"
[ "$PROJECT_PATH" ] || PROJECT_PATH="io/fd/cicn/libparc"
[ "$DOC_FILE" ] || DOC_FILE="cicn.libparc.docs.zip"
[ "$DOC_DIR" ] || DOC_DIR="build/documentation/generated-documentation/html"
[ "$SITE_DIR" ] || SITE_DIR="build/documentation/deploy-site/"
[ "$RESOURCES_DIR" ] || RESOURCES_DIR=${SITE_DIR}/src/site/resources
[ "$MVN" ] || MVN="/opt/apache/maven/bin/mvn"
[ "$VERSION" ] || VERSION=$(bash scripts/version rpm-version)

echo "Current directory: $(pwd)"

update_cmake_repo
mkdir -p build
pushd build
cmake ..
make documentation
popd

if [[ ${JOB_NAME} == *merge* ]]; then
  mkdir -p $(dirname ${RESOURCES_DIR})
  mv -f ${DOC_DIR} ${RESOURCES_DIR}
  cd ${SITE_DIR}
  find . -type f '(' -name '*.md5' -o -name '*.dot' -o -name '*.map' ')' -delete
  cat > pom.xml << EOF
  <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>io.fd.vpp</groupId>
    <artifactId>docs</artifactId>
    <version>1.0.0</version>
    <packaging>pom</packaging>

    <properties>
      <generateReports>false</generateReports>
    </properties>

    <build>
      <extensions>
        <extension>
          <groupId>org.apache.maven.wagon</groupId>
           <artifactId>wagon-webdav-jackrabbit</artifactId>
           <version>2.9</version>
        </extension>
      </extensions>
    </build>
    <distributionManagement>
      <site>
        <id>fdio-site</id>
        <url>dav:${DOCS_REPO_URL}/${PROJECT_PATH}/${VERSION}</url>
      </site>
    </distributionManagement>
  </project>
EOF
  ${MVN} site:site site:deploy -gs "${GLOBAL_SETTINGS_FILE}" -s "${SETTINGS_FILE}" -T 4C
  cd -
fi
