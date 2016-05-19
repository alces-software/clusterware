
.PHONY: test_ruby test all

test_ruby:
	/opt/clusterware/opt/ruby/bin/ruby -Ilib:test /opt/clusterware/lib/ruby/lib/alces/packager/tests/test_*

test: test_ruby

all: test
