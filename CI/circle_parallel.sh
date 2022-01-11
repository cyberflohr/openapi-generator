#!/bin/bash
#
# A bash script to run CircleCI node/test in parallel
#

NODE_INDEX=${CIRCLE_NODE_INDEX:-0}

set -e

export NODE_ENV=test

function cleanup {
  # Show logs of 'petstore.swagger' container to troubleshoot Unit Test failures, if any.
  docker logs petstore.swagger # container name specified in circle.yml
}

trap cleanup EXIT

if [ "$NODE_INDEX" = "1" ]; then
  echo "Running node $NODE_INDEX to test 'samples.circleci' defined in pom.xml ..."
  java -version

  mvn --no-snapshot-updates --quiet verify -Psamples.circleci -Dorg.slf4j.simpleLogger.defaultLogLevel=error

elif [ "$NODE_INDEX" = "2" ]; then
  echo "Running node $NODE_INDEX to test haskell"
  # install haskell
  #curl -sSLk https://get.haskellstack.org/ | sh
  #stack upgrade
  #stack --version
  # prepare r
  sudo sh -c 'echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list'
  gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
  gpg -a --export E084DAB9 | sudo apt-key add -
  sudo apt-get update
  sudo apt-get -y install r-base
  R --version

  # install curl
  sudo apt-get -y build-dep libcurl4-gnutls-dev
  sudo apt-get -y install libcurl4-gnutls-dev

  # Install golang version 1.14
  go version
  sudo mkdir /usr/local/go1.14
  wget -c https://dl.google.com/go/go1.14.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local/go1.14
  export PATH="/usr/local/go1.14/go/bin:$PATH"
  go version

  # run integration tests
  mvn --no-snapshot-updates --quiet verify -Psamples.misc -Dorg.slf4j.simpleLogger.defaultLogLevel=error
elif [ "$NODE_INDEX" = "3" ]; then

  echo "Running node $NODE_INDEX to test 'samples.circleci.node3' defined in pom.xml ..."
  #wget https://www.python.org/ftp/python/3.8.9/Python-3.8.9.tgz
  #tar -xf Python-3.8.9.tgz
  #cd Python-3.8.9
  #./configure --enable-optimizations
  #sudo make altinstall
  sudo apt-get update
  sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl openssl
  rm -Rf /opt/circleci/.pyenv
  curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
  source ~/.bash_profile
  pyenv --version
  pyenv install --list 
  pyenv install 3.6.3
  ls -l /usr/include/openssl
  #CONFIGURE_OPTS="--with-openssl=/usr/include/openssl" pyenv install 3.9.0
  wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1g.tar.gz
  tar zxvf openssl-1.1.1g.tar.gz 
  cd openssl-1.1.1g
  ./config --prefix=/home/circleci/openssl --openssldir=/home/circleci/openssl no-ssl2
  make
  make test
  make install
  cd ..
  export PATH=$HOME/openssl/bin:$PATH
  export LD_LIBRARY_PATH=$HOME/openssl/lib
  export LC_ALL="en_US.UTF-8"
  export LDFLAGS="-L /home/circleci/openssl/lib -Wl,-rpath,/home/circleci/openssl/lib"
  which openssl
  openssl version
  CPPFLAGS=-I$HOME/openssl/include LDFLAGS=-L$HOME/openssl/lib SSH=$HOME/openssl pyenv install -v 3.9.0
  #pyenv install 3.9.0

  pyenv global 3.6.3
  python3 --version

  # Install node@stable (for angular 6)
  set +e
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
  export NVM_DIR="/opt/circleci/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  #nvm install stable
  # install v16 instead of the latest stable version
  nvm install 16
  nvm alias default 16
  node --version

  # Each step uses the same `$BASH_ENV`, so need to modify it
  echo 'export NVM_DIR="/opt/circleci/.nvm"' >> $BASH_ENV
  echo "[ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\"" >> $BASH_ENV

  mvn --no-snapshot-updates --quiet verify -Psamples.circleci.node3 -Dorg.slf4j.simpleLogger.defaultLogLevel=error

else
  echo "Running node $NODE_INDEX to test 'samples.circleci.others' defined in pom.xml ..."
  #sudo update-java-alternatives -s java-1.7.0-openjdk-amd64
  java -version

  mvn --no-snapshot-updates --quiet verify -Psamples.circleci.others -Dorg.slf4j.simpleLogger.defaultLogLevel=error
  mvn --no-snapshot-updates --quiet javadoc:javadoc -Psamples.circleci -Dorg.slf4j.simpleLogger.defaultLogLevel=error
fi


