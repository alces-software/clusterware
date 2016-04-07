FROM centos:7.2.1511
MAINTAINER Alces Software Ltd <support@alces-software.com>

LABEL name="Alces Clusterware 1.4.0 on EL7 (CentOS 7.2.1511)"
LABEL vendor="Alces Software Ltd"
LABEL license="AGPLv3+"

ENV cw_BUILD_source_branch=1.4.0
ENV cw_DIST=el7

RUN yum install -y -e0 openssh-server && yum clean all
RUN curl -sL http://git.io/clusterware-installer | /bin/bash
RUN /opt/clusterware/bin/alces gridware init

# Patches
RUN yum install -y -e0 file which && yum clean all
RUN cd /opt/gridware/depots/* && mkdir -p el7/etc/depends

# Finish off
RUN yum clean all

CMD ["/bin/bash"]
