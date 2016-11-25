.PHONY: build
build: build-release

.PHONY: build-release
build-release:
	@if [ ! -d ./bin/Release/ ]; then mkdir -p ./bin/Release/; fi
	crystal build --error-trace --no-color --release ./src/coke.cr -o ./bin/Release/cake

.PHONY: build-debug
build-debug:
	@if [ ! -d ./bin/Debug/ ]; then mkdir -p ./bin/Debug/; fi
	crystal build --no-color --debug ./src/coke.cr -o ./bin/Debug/cake
