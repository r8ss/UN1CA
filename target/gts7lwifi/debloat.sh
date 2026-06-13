#
# Copyright (C) 2023 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Debloat list for Galaxy Tab S7 (WIFI) (gts7lwifi)

# 1. 고용량 삼성 블로트웨어 및 불필요한 기능 제거 (system 영역)
SYSTEM_DEBLOAT+="
system/app/BixbyWakeUp
system/app/KidsHome_Alpha
system/app/SamsungTrends3
system/app/StickerCenter
system/app/AvatarEmojiSticker
system/app/SamsungMax
system/app/GalaxyWatchRROverlay
system/priv-app/Bixby
system/priv-app/BixbyService
system/priv-app/SamsungSocial
system/priv-app/SecureFolder
system/priv-app/SamsungPass
system/priv-app/SamsungPassAutofill
system/priv-app/LedCoverService
system/priv-app/DigitalWellbeing
system/priv-app/DexDevelopment
"

# 2. 용량 폭탄의 주범 (product 영역 대규모 삭제)
PRODUCT_DEBLOAT+="
product/app/Maps
product/app/YouTube
product/app/Gmail2
product/app/CalendarGoogle
product/app/Chrome
product/app/Photos
product/app/Videos
product/app/SamsungMusic
product/app/SamsungNotes
product/app/SamsungFree
product/app/SamsungGlobalGoals
product/app/SamsungShop
product/app/SamsungMembers
product/app/PreloadInstaller
product/priv-app/Velvet
product/priv-app/GmsCoreCloudSync
product/priv-app/Turbo
product/priv-app/Tips
product/priv-app/MainlineScf
"

# 3. 기본 제공 Overlays
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppLls
"

# 4. mAFPC
SYSTEM_DEBLOAT+="
system/bin/mafpc_write
"

# 5. HDCP
SYSTEM_DEBLOAT+="
system/bin/dhkprov
system/bin/qchdcpkprov
system/etc/init/dhkprov.rc
system/lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so
"

# 6. system_ext clean-up
SYSTEM_EXT_DEBLOAT+="
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.qti.location.sdk.jar
priv-app/com.qualcomm.location
"
