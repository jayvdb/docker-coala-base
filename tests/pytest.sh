#!/bin/sh

set -e -x

export OS_NAME=posix;
cd /coala;
git remote add jv https://github.com/jayvdb/coala
git fetch jv
git checkout jv/fix-test_get_filtered_bears-order
python3 -m pytest;
cd /coala-bears;
rm bears/Constants.py;  # There are no tests covering this module
rm bears/c_languages/CSharpLintBear.py tests/c_languages/CSharpLintBearTest.py;
rm bears/java/InferBear.py tests/java/InferBearTest.py;
rm bears/haskell/GhcModBear.py tests/haskell/GhcModBearTest.py;
rm -r bears/verilog tests/verilog/;
python3 -m pytest --cov --cov-fail-under=100;
