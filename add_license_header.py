#!/usr/bin/env python3
import sys
import os

LICENSE_HEADER = """/*
  This file is part of Pushpin.

  Pushpin is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, version 3.

  Pushpin is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.
  If not, see <https://www.gnu.org/licenses/>.
*/

"""

def prepend_license_header(folder_path):
    for root, dirs, files in os.walk(folder_path):
        for file_name in files:
            if file_name.endswith(('.h', '.m', '.mm')):
                full_path = os.path.join(root, file_name)
                with open(full_path, 'r+') as f:
                    original = f.read()
                    f.seek(0)
                    f.write(LICENSE_HEADER + original)

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <folder_path>")
        sys.exit(1)
    prepend_license_header(sys.argv[1])

if __name__ == "__main__":
    main()
