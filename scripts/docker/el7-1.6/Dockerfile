FROM centos:7.2.1511
MAINTAINER Alces Software Ltd <support@alces-software.com>

LABEL name="(Development) Alces Clusterware 1.6.0 on EL7 (CentOS 7.2.1511)"
LABEL vendor="Alces Software Ltd"
LABEL license="AGPLv3+"

ENV cw_BUILD_source_branch=1.6.0
ENV cw_DIST=el7

RUN yum install -y -e0 openssh-server && yum clean all
RUN echo 1.6.0
RUN curl -sL http://git.io/clusterware-installer | /bin/bash && yum clean all

CMD ["/bin/bash"]
