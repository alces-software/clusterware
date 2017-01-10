FROM centos:7.3.1611
MAINTAINER Alces Software Ltd <support@alces-software.com>

LABEL name="Alces Clusterware 1.7.0 on EL7 (CentOS 7.3.1611)"
LABEL vendor="Alces Software Ltd"
LABEL license="AGPLv3+"

ENV cw_BUILD_source_branch=1.7.0
ENV cw_DIST=el7

RUN yum install -y -e0 openssh-server && yum clean all
RUN echo 1.7.0
RUN curl -sL http://git.io/clusterware-installer | /bin/bash && yum clean all

CMD ["/bin/bash"]
