FROM centos:6.7
MAINTAINER Alces Software Ltd <support@alces-software.com>

LABEL name="(Development) Alces Clusterware 1.6-dev on EL6 (CentOS 6.7)"
LABEL vendor="Alces Software Ltd"
LABEL license="AGPLv3+"

ENV cw_BUILD_source_branch=develop
ENV cw_DIST=el6

RUN yum install -y -e0 openssh-server tar && yum clean all
RUN echo 1.6.0-dev.1
RUN curl -sL http://git.io/clusterware-installer | /bin/bash && yum clean all
RUN /opt/clusterware/bin/alces gridware init

CMD ["/bin/bash"]
