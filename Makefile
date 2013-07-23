HOST = localhost
PORT = 3000

run:
	@bundle exec rerun -- rackup -p $(PORT) --host $(HOST) -s thin

shell:
	@bundle exec irb

test:
	@rspec specs/

install:
	@bundle
