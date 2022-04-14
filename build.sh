#!/bin/sh

set -xe

if [ "$1" = "-w" ] || [ "$1" = "--watch" ]; then
  watchexec -w bin -e dart -r --print-events -- "sh -c './build.sh 2>/dev/null'"
elif [ "$1" = "-d" ] || [ "$1" = "--dist" ]; then
  ./build.sh 2>/dev/null
  dart compile exe -o ./build/battleship ./build/main.dart
else
  dart-concat bin/battleship.dart >build/main.dart
fi
