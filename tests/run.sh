#!/bin/bash
cat tests/round_coordinates.test1.txt | bin/round_coordinates.py > out.txt
diff --brief out.txt tests/round_coordinates.test1expected.txt || exit 1
