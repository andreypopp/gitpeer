HOST = localhost
PORT = 3000

run:
	@bundle exec rerun \
		-p 'lib/*.{rb,ru}' \
		-- rackup -p $(PORT) --host $(HOST) -s thin

shell:
	@bundle exec irb

test:
	@rspec specs/

install:
	@bundle
