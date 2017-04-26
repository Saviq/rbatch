#!/usr/bin/env python3

import os
import subprocess
import sys

action = os.path.basename(sys.argv[0])

unit = subprocess.check_output([
  "systemd-escape",
  "--template",
  "rbatch@.service",
  "{}".format(action)
]).strip()

subprocess.check_call([
  "systemctl",
  "--user",
  "start",
  unit
])
