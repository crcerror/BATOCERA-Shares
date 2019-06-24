#!/usr/bin/env python 

import sys
import os

scriptDir = os.path.dirname(os.path.realpath(__file__))
sys.argv[0]="mimic_python"
str1 = '\n'.join(str(i) for i in sys.argv)
os.system('bash "%s"/batoceraSettings.sh "%s"' % (scriptDir, str1))
