#!/bin/python

import sys

file1 = open(sys.argv[1],"rt")
file2 = open(sys.argv[2],"rt")

def readnext(file, lineno):
	while True:
		line = file.readline()
		if not line:
			return None, lineno
		lineno += 1
		loc = line.find("M1 at address")
		if loc > 0:
			return line[loc:], lineno

line1, lineno1 = readnext(file1, 1)
line2, lineno2 = readnext(file2, 1)

while line1 and line2:
	if line1 != line2:
		print(f"Mismatch at line {lineno1}, {lineno2} == {line1[:-1]} == {line2[:-1]}")

	line1, lineno1 = readnext(file1, 1)
	line2, lineno2 = readnext(file2, 1)
	if line1 is None and line2 is not None:
		print(f"{sys.argv[1]} is shorter")
		break
	if line2 is None and line1 is not None:
		print(f"{sys.argv[2]} is shorter")
		break


#close(file1)
#close(file2)
print("done")
