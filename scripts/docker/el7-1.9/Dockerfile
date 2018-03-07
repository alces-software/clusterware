FROM centos:7.4.1708
MAINTAINER Alces Software Ltd <support@alces-software.com>

LABEL name="Alces Clusterware 1.9.0 on EL7 (CentOS 7.4.1708)"
LABEL vendor="Alces Software Ltd"
LABEL license="AGPLv3+"

ENV cw_BUILD_source_branch=1.9.0
ENV cw_DIST=el7

RUN yum install -y -e0 openssh-server && yum clean all
RUN echo 1.9.0
RUN curl -sL http://git.io/clusterware-installer | /bin/bash && yum clean all
RUN sed -i -e 's/gridware-20171121-cw1_9/gridware-20180116-cw2_0/g' /opt/clusterware/etc/serviceware.rc
RUN sed -i -e 's/clusterware-dropbox-cli-v2.0.0-cw1_8/clusterware-dropbox-cli-v2.0.1-cw1_9/g' /opt/clusterware/etc/serviceware.rc
CMD ["/bin/bash"]
