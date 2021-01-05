#!/usr/bin/python3

import sqlparse
import sys

from sqlparse.sql import IdentifierList, Identifier
from sqlparse.tokens import Keyword, DML

if __name__ == '__main__':
  if len(sys.argv) < 3:
    sys.exit("Usage: qsh-formatter.py <input-file> <output-file>")

  inputFile = sys.argv[1]
  outputFile = sys.argv[2]

  inputData = ""
  with open(inputFile) as input:
    inputData = input.read()

  with open(outputFile, 'w') as output:
    output.write(sqlparse.format(inputData, reindent=True, keyword_case='lower'))
    output.write("\n");
