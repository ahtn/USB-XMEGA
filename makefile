SRC_USB += $(USB_PATH)/usb_xmega.c
SRC_USB += $(USB_PATH)/usb_requests.c
USB_OPTS += -I $(USB_PATH)

# workaround for bad code generation on avr-gcc on linux (version 6.2.0)
CFLAGS += -fno-jump-tables
