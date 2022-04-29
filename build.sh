#!/bin/sh

set -xe

mkdir -p build

if [ "$1" = "-w" ] || [ "$1" = "--watch" ]; then
  watchexec -w bin -e dart -r --print-events -- "sh -c '$0 2>/dev/null'"
elif [ "$1" = "-d" ] || [ "$1" = "--dist" ]; then
  $0 2>/dev/null
  dart compile exe -o ./build/battleship ./build/main.dart
else
  dart-concat bin/battleship.dart >build/main.dart
fi
