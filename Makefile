DEBUG=0
FRONTEND_SUPPORTS_RGB565=1
TARGET_NAME=tyrquake
STATIC_LINKING=0

ifeq ($(platform),)
platform = unix
ifeq ($(shell uname -a),)
   platform = win
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   platform = osx
	arch = intel
ifeq ($(shell uname -p),powerpc)
	arch = ppc
endif
else ifneq ($(findstring win,$(shell uname -a)),)
   platform = win
endif
endif

# system platform
system_platform = unix
ifeq ($(shell uname -a),)
EXE_EXT = .exe
   system_platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   system_platform = osx
	arch = intel
ifeq ($(shell uname -p),powerpc)
	arch = ppc
endif
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   system_platform = win
endif

LIBM := -lm

ifeq ($(ARCHFLAGS),)
ifeq ($(archs),ppc)
   ARCHFLAGS = -arch ppc -arch ppc64
else
   ARCHFLAGS = -arch i386 -arch x86_64
endif
endif

ifeq ($(STATIC_LINKING),1)
EXT=a

ifeq ($(platform), unix)
PLAT=_unix
endif
endif

# UNIX
ifeq ($(platform), unix)
	EXT    ?= so
   TARGET := $(TARGET_NAME)_libretro$(PLAT).$(EXT)
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=common/libretro-link.T

# Linux (portable library)
else ifeq ($(platform), linux-portable)
	EXT    ?= so
	TARGET := $(TARGET_NAME)_libretro.$(EXT)
   fpic := -fPIC -nostdlib
   SHARED := -shared -Wl,--version-script=common/libretro-link.T
	LIBM :=

# OS X
else ifeq ($(platform), osx)
	EXT    ?= dylib
	TARGET := $(TARGET_NAME)_libretro.$(EXT)
   fpic := -fPIC
   SHARED := -dynamiclib
ifeq ($(arch),ppc)
   CFLAGS += -D__ppc__ -DMSB_FIRST
endif
   OSXVER = `sw_vers -productVersion | cut -d. -f 2`
   OSX_LT_MAVERICKS = `(( $(OSXVER) <= 9)) && echo "YES"`
   fpic += -mmacosx-version-min=10.1

# iOS
else ifneq (,$(findstring ios,$(platform)))
	EXT    ?= dylib
	TARGET := $(TARGET_NAME)_libretro_ios.$(EXT)
   fpic := -fPIC
   SHARED := -dynamiclib

ifeq ($(IOSSDK),)
   IOSSDK := $(shell xcodebuild -version -sdk iphoneos Path)
endif

   CC = clang -arch armv7 -isysroot $(IOSSDK)
   CFLAGS += -DIOS
ifeq ($(platform),ios9)
	CC     += -miphoneos-version-min=8.0
	CFLAGS += -miphoneos-version-min=8.0
else
	CC     += -miphoneos-version-min=5.0
	CFLAGS += -miphoneos-version-min=5.0
endif

# iOS Theos
else ifeq ($(platform), theos_ios)
DEPLOYMENT_IOSVERSION = 5.0
TARGET = iphone:latest:$(DEPLOYMENT_IOSVERSION)
ARCHS = armv7 armv7s
TARGET_IPHONEOS_DEPLOYMENT_VERSION=$(DEPLOYMENT_IOSVERSION)
THEOS_BUILD_DIR := objs
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = $(TARGET_NAME)_libretro_ios

# QNX
else ifeq ($(platform), qnx)
	EXT    ?= so
   TARGET := $(TARGET_NAME)_libretro_qnx.$(EXT)
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=common/libretro-link.T
	CC = qcc -Vgcc_ntoarmv7le
	AR = qcc -Vgcc_ntoarmv7le
	CFLAGS += -D__BLACKBERRY_QNX__ -marm -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=softfp

# PS3
else ifeq ($(platform), ps3)
	EXT=a
   TARGET := $(TARGET_NAME)_libretro_ps3.$(EXT)
   CC = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-gcc.exe
   AR = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-ar.exe
   CFLAGS += -D__ppc__ -DMSB_FIRST
	STATIC_LINKING = 1

# PS3 (SNC)
else ifeq ($(platform), sncps3)
	EXT=a
   TARGET := $(TARGET_NAME)_libretro_ps3.$(EXT)
   CC = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
   AR = $(CELL_SDK)/host-win32/sn/bin/ps3snarl.exe
   CFLAGS += -D__ppc__ -DMSB_FIRST
	STATIC_LINKING = 1
else ifeq ($(platform), psl1ght)
	EXT=a
   TARGET := $(TARGET_NAME)_libretro_psl1ght.$(EXT)
   CC = $(PS3DEV)/ppu/bin/ppu-gcc$(EXE_EXT)
   AR = $(PS3DEV)/ppu/bin/ppu-ar$(EXE_EXT)
   CFLAGS += -D__ppc__ -DMSB_FIRST
	STATIC_LINKING = 1

# PSP1
else ifeq ($(platform), psp1)
	EXT=a
	TARGET := $(TARGET_NAME)_libretro_psp1.$(EXT)
	CC = psp-gcc$(EXE_EXT)
	AR = psp-ar$(EXE_EXT)
	CFLAGS += -DPSP -G0 -I$(shell psp-config --pspsdk-path)/include
	STATIC_LINKING = 1

# Vita
else ifeq ($(platform), vita)
	EXT=a
	TARGET := $(TARGET_NAME)_libretro_vita.$(EXT)
	CC = arm-vita-eabi-gcc$(EXE_EXT)
	AR = arm-vita-eabi-ar$(EXE_EXT)
	CFLAGS += -DVITA
	STATIC_LINKING = 1

# CTR (3DS)
else ifeq ($(platform), ctr)
	EXT=a
	TARGET := $(TARGET_NAME)_libretro_ctr.$(EXT)
	CC = $(DEVKITARM)/bin/arm-none-eabi-gcc$(EXE_EXT)
	AR = $(DEVKITARM)/bin/arm-none-eabi-ar$(EXE_EXT)
	CFLAGS += -DARM11 -D_3DS
	CFLAGS += -march=armv6k -mtune=mpcore -mfloat-abi=hard
	CFLAGS += -Wall -mword-relocations
	CFLAGS += -fomit-frame-pointer -ffast-math
	STATIC_LINKING = 1

# Libxenon
else ifeq ($(platform), xenon)
	EXT=a
	TARGET := $(TARGET_NAME)_libretro_xenon360.$(EXT)
   CC = xenon-gcc$(EXE_EXT)
   AR = xenon-ar$(EXE_EXT)
   CFLAGS += -D__LIBXENON__ -m32 -D__ppc__ -DMSB_FIRST
	STATIC_LINKING = 1

# Nintendo Game Cube
else ifeq ($(platform), ngc)
	EXT=a
   TARGET := $(TARGET_NAME)_libretro_ngc.$(EXT)
   CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
   AR = $(DEVKITPPC)/bin/powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -DGEKKO -DHW_DOL -mrvl -mcpu=750 -meabi -mhard-float -D__ppc__ -DMSB_FIRST -I$(DEVKITPRO)/libogc/include
	STATIC_LINKING = 1

# Nintendo Wii
else ifeq ($(platform), wii)
   TARGET := $(TARGET_NAME)_libretro_wii.a
   CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
   AR = $(DEVKITPPC)/bin/powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -DGEKKO -DHW_RVL -mrvl -mcpu=750 -meabi -mhard-float -D__ppc__ -DMSB_FIRST -I$(DEVKITPRO)/libogc/include
	STATIC_LINKING = 1

# ARM
else ifneq (,$(findstring armv,$(platform)))
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=common/libretro-link.T
ifneq (,$(findstring cortexa8,$(platform)))
   CFLAGS += -marm -mcpu=cortex-a8
else ifneq (,$(findstring cortexa9,$(platform)))
   CFLAGS += -marm -mcpu=cortex-a9
endif
   CFLAGS += -marm
ifneq (,$(findstring neon,$(platform)))
   CFLAGS += -mfpu=neon
   HAVE_NEON = 1
endif
ifneq (,$(findstring softfloat,$(platform)))
   CFLAGS += -mfloat-abi=softfp
else ifneq (,$(findstring hardfloat,$(platform)))
   CFLAGS += -mfloat-abi=hard
endif
   CFLAGS += -DARM

# Emscripten
else ifeq ($(platform), emscripten)
	EXT    ?= bc
	TARGET := $(TARGET_NAME)_libretro_emscripten.$(EXT)

# Windows
else
	EXT    ?= dll
	TARGET := $(TARGET_NAME)_libretro.$(EXT)
   CC = gcc
   fpic :=
   LD_FLAGS :=
   SHARED := -shared -static-libgcc -static-libstdc++ -s
   CFLAGS += -D__WIN32__ -D__WIN32_LIBRETRO__
   WINSOCKS := -lws2_32
endif

ifeq ($(STATIC_LINKING),1)
SHARED=
fpic=
endif

ifeq ($(DEBUG), 1)
CFLAGS += -O0 -g
else ifeq ($(platform), emscripten)
CFLAGS += -O2 -DNDEBUG
else
CFLAGS += -O3 -DNDEBUG
endif

LDFLAGS += $(LIBM)
CORE_DIR := .

include Makefile.common

OBJECTS    = $(SOURCES_C:.c=.o)

DEFINES    = -DHAVE_STRINGS_H -DHAVE_STDINT_H -DHAVE_INTTYPES_H -D__LIBRETRO__ -DINLINE=inline -DNQ_HACK -DQBASEDIR=$(CORE_DIR) -DTYR_VERSION=0.62

ifeq ($(platform), sncps3)
WARNINGS_DEFINES =
CODE_DEFINES =
else ifeq ($(platform), ios)
WARNINGS_DEFINES =
CODE_DEFINES =
else ifeq ($(platform), emscripten)
WARNINGS_DEFINES = -Wall
CODE_DEFINES = -fomit-frame-pointer
else
WARNINGS_DEFINES = -Wall
CODE_DEFINES = -fomit-frame-pointer
endif

COMMON_DEFINES += $(CODE_DEFINES) $(WARNINGS_DEFINES) $(fpic)

CFLAGS     += $(DEFINES) $(COMMON_DEFINES)

ifeq ($(FRONTEND_SUPPORTS_RGB565), 1)
CFLAGS += -DFRONTEND_SUPPORTS_RGB565
endif

ifeq ($(platform), osx)
ifndef ($(NOUNIVERSAL))
   CFLAGS += $(ARCHFLAGS)
   LFLAGS += $(ARCHFLAGS)
endif
endif

ifeq ($(platform), theos_ios)
COMMON_FLAGS := -DIOS $(COMMON_DEFINES) $(INCFLAGS) -I$(THEOS_INCLUDE_PATH) -Wno-error
$(LIBRARY_NAME)_CFLAGS += $(COMMON_FLAGS)
${LIBRARY_NAME}_FILES = $(SOURCES_C)
include $(THEOS_MAKE_PATH)/library.mk
else
all: $(TARGET)

$(TARGET): $(OBJECTS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else
	$(CC) $(fpic) $(SHARED) $(INCFLAGS) -o $@ $(OBJECTS) $(LDFLAGS) $(WINSOCKS)
endif

%.o: %.c
	$(CC) $(INCFLAGS) $(CFLAGS) -c -o $@ $<

clean-objs:
	rm -rf $(OBJECTS)

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: clean
endif
