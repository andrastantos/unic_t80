#!/bin/python
import argparse

parser = argparse.ArgumentParser(
    prog='ram_init',
    description='Crate an initialized SRAM block from a binary file as content',
    epilog='================================'
)
parser.add_argument('-i', '--infile', required=True)
parser.add_argument('-t', '--template', required=True)
parser.add_argument('-o', '--outfile', required=True)
parser.add_argument('-n', '--entity_name', required=True)
#parser.add_argument('-e', '--endian', default='big', choices=('big', 'little'))

args = parser.parse_args()

with open(args.template, "rt") as template_file:
    template = template_file.read()

content_str = ""
with open(args.infile, "rb") as in_file:
    while (byte := in_file.read(1)):
        byte_as_int = int.from_bytes(byte, 'big')
        content_str += f'        X"{byte_as_int:02x}",\n'

content_str = content_str[:-2] # delete final new-line and comma

final = template.replace("$$$CONTENT$$$", content_str)
final = final.replace("$$$ENTITY$$$", args.entity_name)

with open(args.outfile, "wt") as out_file:
    out_file.write(final)

