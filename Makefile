# Configuration variables.

# Microcontroller options.
DF_CPU ?= 16000000UL
MMCU   ?= atmega328p

# Port to flash to.
PORT ?= /dev/$(shell ls /dev/ | grep "tty\.usb" | sed -n 1p)

# UART baud rate.
# 115200 - Arduino Uno
# 57600  - Arduino Mini Pro
BAUD ?= 115200

# The language we're building from (C or Assembly), default is C.
LANGUAGE ?= c

################################

# Probably shouldn't touch these.

# The `gcc` executable.
CC = avr-gcc
C_FLAGS = -Wall -Werror -pedantic -Os -std=c99

# The `as` executable.
AS = avr-as

# The `obj-copy` executable.
OBJ_COPY = avr-objcopy
OBJ_COPY_FLAGS = -O ihex -R .eeprom

# The `avrdude` executable.
AVRDUDE = avrdude
AVRDUDE_FLAGS = -F -V -c arduino -p ATMEGA328P

# The `avr-size` executable.
AVRSIZE = avr-size
AVRSIZE_FLAGS = -C

# The source file.
ifneq ($(TARGET),)
SOURCE = $(TARGET).$(LANGUAGE)
endif

# Libraries.
C_LIBS = $(wildcard lib/*.c)

################################

# The default task is to flash.
default: flash

################################

# Pseudo rules.

# These rules are not file based.
.PHONY: flash serial size clean

# Mark the hex file as intermediate.
.INTERMEDIATE: $(TARGET).hex $(TARGET).bin

################################

# Utility rules (not file based).

# flash
#
# Given a hex file using `avrdude` this target flashes the AVR with the
# new program contained in the hex file.
flash: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -P $(PORT) -b $(BAUD) -U flash:w:$<

# serial
#
# Open up a screen session for communication with the AVR
# through it's on-board UART.
serial:
	screen $(PORT) $(BAUD)

# size
#
# Show information about target's size.
size: $(TARGET).bin
	$(AVRSIZE) $(AVRSIZE_FLAGS) --mcu=$(MMCU) $<

# Remove non-source files.
clean:
	rm -rf **/*.o *.o *.bin *.hex

################################

# File rules.

# .bin <- .o
ifeq ($(LANGUAGE), c)
%.bin: %.o $(C_LIBS:.c=.o)
	$(CC) -mmcu=$(MMCU) $? -o $@
else
%.bin: %.o
	$(CC) -mmcu=$(MMCU) $? -o $@
endif

# .asm <- .c
%.asm: %.c
	$(CC) -S $(C_FLAGS) -DF_CPU=$(DF_CPU) -mmcu=$(MMCU) -c $< -o $@

# .o <- (.c | .asm)
ifeq ($(LANGUAGE), c)
%.o: %.c
	$(CC) $(C_FLAGS) -DF_CPU=$(DF_CPU) -mmcu=$(MMCU) -c $< -o $@
else
%.o: %.asm
	$(AS) -mmcu=$(MMCU) -o $@ $<
endif

# .hex <- .bin
%.hex: %.bin
	$(OBJ_COPY) $(OBJ_COPY_FLAGS) $< $@
