
.PHONY: develop test_ruby test all

develop:
	(source /opt/clusterware/etc/distro.rc && cw_BUILD_source_dir=/media/host/clusterware /media/host/clusterware/scripts/develop)


test_ruby:
	(cd /opt/clusterware/lib/ruby && /opt/clusterware/opt/ruby/bin/rake test)

test: test_ruby

all: test
