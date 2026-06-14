#
# Copyright (C) 2023 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later
#

# ==========================================
# 1. System 파티션 디블로트 (system/ 명시 필수)
# ==========================================
SYSTEM_DEBLOAT+="
system/app/BixbyWakeUp
system/app/KidsHome_Alpha
system/app/SamsungTrends3
system/app/StickerCenter
system/app/AvatarEmojiSticker
system/app/SamsungMax
system/app/GalaxyWatchRROverlay
system/app/WifiRROverlayAppLls
system/app/Scribe
system/app/BluetoothMidiService
system/priv-app/Bixby
system/priv-app/BixbyService
system/priv-app/SamsungSocial
system/priv-app/SecureFolder
system/priv-app/SamsungPass
system/priv-app/SamsungPassAutofill
system/priv-app/LedCoverService
system/priv-app/DigitalWellbeing
system/priv-app/DexDevelopment
system/priv-app/LinkToWindowsService
system/priv-app/YourPhoneCompanionSoftware
system/priv-app/SmartSwitchAssistant
system/priv-app/SamsungCompass
system/bin/mafpc_write
system/bin/dhkprov
system/bin/qchdcpkprov
system/etc/init/dhkprov.rc
system/lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so
"

# ==========================================
# 2. Product 파티션 디블로트 (product/ 명시 필수)
# ==========================================
# 여기가 지금 822MB로 터지기 직전인 주범 구역이야. 
# 이번엔 경로 다 맞췄으니 구글 Velvet이랑 삼멤 제대로 찢길 거임.
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
product/app/AREmoji
product/app/AvatarEmojiEditor
product/app/EmojiUpdater
product/app/WallpaperEffects
product/priv-app/Velvet
product/priv-app/GmsCoreCloudSync
product/priv-app/Turbo
product/priv-app/Tips
product/priv-app/MainlineScf
product/priv-app/Upday
"

# ==========================================
# 3. System_ext 파티션 디블로트 (system_ext/ 명시 필수)
# ==========================================
# 전 개발자가 경로 빼먹어서 찌꺼기 남던 하단 클린업 중복 코드 통합 정리완료.
SYSTEM_EXT_DEBLOAT+="
system_ext/etc/permissions/com.qti.location.sdk.xml
system_ext/etc/permissions/com.qualcomm.location.xml
system_ext/etc/permissions/privapp-permissions-com.qualcomm.location.xml
system_ext/framework/com.qti.location.sdk.jar
system_ext/priv-app/com.qualcomm.location
system_ext/priv-app/Pluspot
"
