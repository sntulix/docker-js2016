FROM ubuntu:trusty
MAINTAINER Takahiro Shizuki <shizu@futuregadget.com>

ENV HOST_HOME $HOME
ENV CLIENT_HOME /root


# set package repository mirror
RUN sed -i.bak -e "s%http://archive.ubuntu.com/ubuntu/%http://ftp.iij.ad.jp/pub/linux/ubuntu/archive/%g" /etc/apt/sources.list

# dependencies
RUN apt-get update -o Acquire::ForceIPv4=true
RUN apt-get install -y p7zip bzip2 cmake curl git man nkf ntp psmisc software-properties-common tmux unzip vim wget
RUN apt-get clean

# git latest
RUN add-apt-repository -y ppa:git-core/ppa
RUN apt-get update -o Acquire::ForceIPv4=true
RUN apt-get install -y git tig


# x window relations
RUN apt-get -y install insserv sysv-rc-conf python-appindicator xterm xfce4-terminal leafpad vim-gtk
RUN apt-get clean


# Install dev packages
RUN apt-get install -y gcc-4.7 make autoconf automake
RUN apt-get clean
RUN ln -sf /usr/bin/gcc-4.7 /usr/bin/gcc


# ansible2
RUN apt-get -y install python-dev python-pip
RUN pip install ansible markupsafe
RUN mkdir -p $CLIENT_HOME/ansible
RUN bash -c 'echo 127.0.0.1 ansible_connection=local > $CLIENT_HOME/ansible/localhost'



# Option, User Environment

# japanese packages
RUN wget -t 1 -q https://www.ubuntulinux.jp/ubuntu-ja-archive-keyring.gpg -O- | apt-key add -
RUN wget -t 1 -q https://www.ubuntulinux.jp/ubuntu-jp-ppa-keyring.gpg -O- | apt-key add -
RUN wget -t 1 https://www.ubuntulinux.jp/sources.list.d/wily.list -O /etc/apt/sources.list.d/ubuntu-ja.list
RUN apt-get update -o Acquire::ForceIPv4=true
RUN apt-get -y install language-pack-ja-base language-pack-ja fonts-ipafont-gothic dbus-x11
RUN apt-get -y install ibus-skk
RUN apt-get -y install skkdic skkdic-cdb skkdic-extra skksearch skktools
RUN update-locale LANG=ja_JP.UTF-8 LANGUAGE=ja_JP:ja
RUN apt-get clean

ENV LANG ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8
ENV LC_CTYPE ja_JP.UTF-8

ENV GTK_IM_MODULE ibus
ENV QT_IM_MODULE ibus
ENV XMODIFIERS @im=ibus
RUN echo "ibus-daemon -drx" >> $CLIENT_HOME/.bashrc


# diff merge
WORKDIR $CLIENT_HOME/src
RUN wget -t 1 http://download-us.sourcegear.com/DiffMerge/4.2.0/diffmerge_4.2.0.697.stable_amd64.deb
RUN dpkg -i diffmerge_4.2.0.697.stable_amd64.deb


# Set Env
ENV SHELL /bin/bash
RUN mkdir $CLIENT_HOME/.ssh
RUN chmod 600 $CLIENT_HOME/.ssh
RUN git config --global push.default simple

# Set Timezone
RUN cp /usr/share/zoneinfo/Japan /etc/localtime

# OpenGL env
env LIBGL_ALWAYS_INDIRECT 1
#env DRI_PRIME 1


# Install Apache2
RUN apt-get install -y apache2 apache2-dev
RUN apt-get clean
COPY apache2.conf /etc/apache2/
COPY envvars /etc/envvars/
COPY 000-default.conf /etc/apache2/sites-enabled/


# options
# .bashrc
RUN bash -c 'echo alias ls=\"ls --color\" >> $CLIENT_HOME/.bashrc'


# git config
ENV GIT_USER_NAME "Takahiro Shizuki"
ENV GIT_USER_EMAIL "shizu@futuregadget.com"
RUN git config --global user.name $GIT_USER_NAME
RUN git config --global user.email $GIT_USER_EMAIL


# docker run
WORKDIR $CLIENT_HOME
ENV DISPLAY 192.168.99.1:0
ADD ansible $CLIENT_HOME/ansible
RUN ansible-playbook -v --extra-vars "taskname=copy_ssh" ansible/playbook.yml
RUN ansible-playbook -v --extra-vars "taskname=packages_option" ansible/playbook.yml
RUN ansible-playbook -v --extra-vars "taskname=ricty_diminished-font" ansible/playbook.yml
RUN ansible-playbook -v --extra-vars "taskname=genshin-font" ansible/playbook.yml
RUN ansible-playbook -v --extra-vars "taskname=postgresql" ansible/playbook.yml
RUN ansible-playbook -v --extra-vars "taskname=php" ansible/playbook.yml
RUN ansible-playbook -v --extra-vars "taskname=js2016" ansible/playbook.yml
#RUN ansible-playbook -v --extra-vars "taskname=angular2" ansible/playbook.yml
WORKDIR $CLIENT_HOME
CMD xfce4-terminal
