#
# Copyright (C) 2023 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later
#

# 1. System
SYSTEM_DEBLOAT+="
app/BixbyWakeUp
app/KidsHome_Alpha
app/SamsungTrends3
app/StickerCenter
app/AvatarEmojiSticker
app/SamsungMax
app/GalaxyWatchRROverlay
app/WifiRROverlayAppLls
priv-app/Bixby
priv-app/BixbyService
priv-app/SamsungSocial
priv-app/SecureFolder
priv-app/SamsungPass
priv-app/SamsungPassAutofill
priv-app/LedCoverService
priv-app/DigitalWellbeing
priv-app/DexDevelopment
bin/mafpc_write
bin/dhkprov
bin/qchdcpkprov
etc/init/dhkprov.rc
lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so
"

# 2. Product
PRODUCT_DEBLOAT+="
app/Maps
app/YouTube
app/Gmail2
app/CalendarGoogle
app/Chrome
app/Photos
app/Videos
app/SamsungMusic
app/SamsungNotes
app/SamsungFree
app/SamsungGlobalGoals
app/SamsungShop
app/SamsungMembers
app/PreloadInstaller
priv-app/Velvet
priv-app/GmsCoreCloudSync
priv-app/Turbo
priv-app/Tips
priv-app/MainlineScf
"

# 3. System_ext 영역 삭제
SYSTEM_EXT_DEBLOAT+="
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.qti.location.sdk.jar
priv-app/com.qualcomm.location
"


# 4. Overlays
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppLls
"

# 5. mAFPC
SYSTEM_DEBLOAT+="
system/bin/mafpc_write
"

# 6. HDCP
SYSTEM_DEBLOAT+="
system/bin/dhkprov
system/bin/qchdcpkprov
system/etc/init/dhkprov.rc
system/lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so
"

# 7. system_ext clean-up
SYSTEM_EXT_DEBLOAT+="
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.qti.location.sdk.jar
priv-app/com.qualcomm.location
"
