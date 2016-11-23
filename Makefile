.PHONY: build
build: build-release

.PHONY: build-release
build-release:
	@if [ ! -d ./bin/Release/ ]; then mkdir -p ./bin/Release/; fi
	crystal build --release --link-flags -Os ./src/coke.cr -o ./bin/Release/cake

.PHONY: build-debug
build-debug:
	@if [ ! -d ./bin/Debug/ ]; then mkdir -p ./bin/Debug/; fi
	crystal build --debug ./src/coke.cr -o ./bin/Debug/cake
