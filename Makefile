
.PHONY: test_ruby test all

test_ruby:
	(cd /opt/clusterware/lib/ruby && /opt/clusterware/opt/ruby/bin/rake test)

test: test_ruby

all: test
