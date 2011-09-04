include theos/makefiles/common.mk

TWEAK_NAME = FlowChatMod
FlowChatMod_FILES = Tweak.xm
FlowChatMod_FRAMEWORKS = MediaPlayer AVFoundation UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
