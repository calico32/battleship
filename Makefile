.PHONY: concat
concat: builddir
	dart run dart-concat/concat.dart bin/battleship.dart >build/main.dart

.PHONY: gdocs
gdocs: builddir
	dart run dart-concat/concat.dart --gdocs bin/battleship.dart >build/main.dart

.PHONY: dist
dist: concat
	dart compile exe -o ./build/battleship ./build/main.dart

.PHONY: watch
watch:
	watchexec -w bin -e dart -r --print-events -- "${MAKE} concat"

builddir: build
	mkdir -p build
