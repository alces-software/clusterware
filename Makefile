
.PHONY: test_ruby test all

test_ruby:
	/opt/clusterware/opt/ruby/bin/rake test

test: test_ruby

all: test
