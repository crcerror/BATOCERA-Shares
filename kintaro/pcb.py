#!/usr/bin/python
# -*- coding: utf-8 -*-

import time
import os
import subprocess
import string
import RPi.GPIO as GPIO

# Initialize
GPIO.setwarnings(False)
GPIO.cleanup()
GPIO.setmode(GPIO.BOARD)
PCB = 10
RESET = 3
POWER = 5
LED = 7
FAN = 8

# Setup
GPIO.setup(PCB, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(RESET, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(POWER, GPIO.IN)
GPIO.setup(LED, GPIO.OUT)
GPIO.setup(FAN, GPIO.OUT)
IGNORE_PWR_OFF = False
if(GPIO.input(POWER) == "0"):
	# System was started with power switch off
	IGNORE_PWR_OFF = True

# Turn on LED AND FAN
GPIO.output(LED, GPIO.HIGH)
GPIO.output(FAN, GPIO.HIGH)

# Function that blinks LED once when button press is detected
def Blink_LED():
	GPIO.output(LED, GPIO.LOW)
	time.sleep(0.2)
	GPIO.output(LED, GPIO.HIGH)

# Monitor for Inputs
while True:
	if(GPIO.input(PCB) == "0"):
		if(GPIO.input(RESET) == "0"):
			print("Rebooting...")
			Blink_LED()
			os.system("batocera-es-swissknife --reboot")
			break
		if(GPIO.input(POWER) == "1" and IGNORE_PWR_OFF == True):
			IGNORE_PWR_OFF = False
		if(GPIO.input(POWER) == "0" and IGNORE_PWR_OFF == False):
			print("Shutting down...")
			Blink_LED()
			GPIO.output(FAN, GPIO.LOW)
			os.system("batocera-es-swissknife --shutdown")
			break
	else:
		print("Roshambo Case not found")
		break
	time.sleep(0.3)

GPIO.output(FAN, GPIO.LOW)
GPIO.cleanup()
