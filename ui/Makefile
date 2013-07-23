BIN = ./node_modules/.bin
SRC = $(wildcard *.coffee)
LIB = $(SRC:%.coffee=%.js)
REPO = $(shell cat .git/config | grep url | xargs echo | sed -E 's/^url = //g')
REPONAME = $(shell echo $(REPO) | sed -E 's_.+:([a-zA-Z0-9_\-]+)/([a-zA-Z0-9_\-]+)\.git_\1/\2_')
STYLUS_OPTS = --include ./node_modules/normalize/lib \
							--use nib --use foundation

watch:
	$(MAKE) -j2 watch-js watch-css

watch-js:
	@$(BIN)/watchify -vv --debug -t coffeeify -t reactify -o assets/index.js index.coffee

watch-css:
	@$(BIN)/stylus $(STYLUS_OPTS) --watch -o ./assets index.styl

css:
	@$(BIN)/stylus $(STYLUS_OPTS) -o ./assets index.styl

build: $(LIB)

%.js: %.coffee
	@mkdir -p $(@D)
	@$(BIN)/coffee -bcp $< > $@

clean:
	@rm -rf $(LIB) npm-debug.log

install link:
	@npm $@

test:
	@#$(BIN)/mocha -b -R spec --compilers coffee:coffee-script ./specs/*.coffee

release-patch: build test
	@$(call release,patch)

release-minor: build test
	@$(call release,minor)

release-major: build test
	@$(call release,major)

publish:
	git push --tags origin HEAD:master
	npm publish

define release
	VERSION=`node -pe "require('./package.json').version"` && \
	NEXT_VERSION=`node -pe "require('semver').inc(\"$$VERSION\", '$(1)')"` && \
  node -e "\
  	var j = require('./package.json');\
  	j.version = \"$$NEXT_VERSION\";\
  	var s = JSON.stringify(j, null, 2);\
  	require('fs').writeFileSync('./package.json', s);" && \
  git commit -m "release $$NEXT_VERSION" -- package.json && \
  git tag "$$NEXT_VERSION" -m "release $$NEXT_VERSION"
endef
