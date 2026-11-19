.PHONY: generate build test

generate:
	xcodegen generate

build: generate
	xcodebuild -scheme SwitchPanel -configuration Debug -destination 'platform=macOS' build

test: generate
	xcodebuild -scheme SwitchPanel -destination 'platform=macOS' test