#!/usr/bin/env python
# https://howchoo.com/g/mwnlytk3zmm/how-to-add-a-power-button-to-your-raspberry-pi
# https://howchoo.com/g/ytzjyzy4m2e/build-a-simple-raspberry-pi-led-power-status-indicator
# https://www.raspberrypi.org/forums/viewtopic.php?f=32&t=133621&p=890444#p890444
import RPi.GPIO as GPIO
import time 
import subprocess

# Constants
button = 3 
led = 14
hold_delay = 3
debounce_delay = 0.25

# GPIO Setup
GPIO.setwarnings(False)
# GPIO.setmode (GPIO.BOARD)
GPIO.setmode(GPIO.BCM)
# GPIO.setup(button,GPIO.IN,pull_up_down = GPIO.PUD_UP) # Internal Pullup Resistor
GPIO.setup(button ,GPIO.IN)  # Physical External Pullup Resistor
GPIO.setup(led,GPIO.OUT)
GPIO.output(led,GPIO.HIGH)

while True:
   if GPIO.input(button) == GPIO.LOW:
      time.sleep(debounce_delay) # Button Debounce
      start_time = time.time()

      # Loop While Pressed
      while GPIO.input(button) == GPIO.LOW:

         # Check if hold_delay has elapsed 
         if time.time() - start_time > hold_delay - debounce_delay:
            # Shutdown
            GPIO.output(14, GPIO.HIGH)
            subprocess.call(['shutdown', '-h', 'now'], shell=False)
         else:
            # Blink LED
            GPIO.output(led,GPIO.LOW)
            time.sleep(0.1)
            GPIO.output(14, GPIO.HIGH)
            time.sleep(0.1)
   else:
      time.sleep(debounce_delay) # debounce
