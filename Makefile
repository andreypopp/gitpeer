HOST = localhost
PORT = 3002

run:
	@bundle exec rerun \
		-p '**/*.{rb,ru}' \
		-- rackup -p $(PORT) --host $(HOST) -s thin

shell::
	@bundle exec racksh

test specs::
	@rspec specs/

install:
	@bundle
