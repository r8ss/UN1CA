#
# Copyright (c) 2026 JeyKul & Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#

# UN1CA ROM configuration file for Snapdragon tablet devices

case "$TARGET_CODENAME" in
    gts7lwifi|gts7xlwifi)
        # ==========================================
        # Galaxy Tab S7 / S7+ (WiFi) Porting Target
        # ==========================================

        # OS & Base Specification (Tab S8 Base Dynamic Configuration)
        SOURCE_FIRMWARE="SM-X800/KOO/R54W100KMDT"
        SOURCE_EXTRA_FIRMWARES=()
        SOURCE_SUPER_GROUP_NAME="qti_dynamic_partitions"
        SOURCE_HAS_SYSTEM_EXT=true

        # API Level Matching
        SOURCE_PLATFORM_SDK_VERSION=36
        SOURCE_BOARD_API_LEVEL=34
        SOURCE_PRODUCT_SHIPPING_API_LEVEL=33

        # Target Specification Injection (From JeyKul Config)
        TARGET_OS_SINGLE_SYSTEM_IMAGE="tqssi"
        TARGET_OS_BUILD_SYSTEM_EXT_PARTITION=false
        TARGET_PLATFORM_SDK_VERSION=33
        TARGET_PRODUCT_SHIPPING_API_LEVEL=30
        TARGET_BOARD_API_LEVEL=30

        # Dynamic Partitions Geometry
        TARGET_USE_DYNAMIC_PARTITIONS=true
        TARGET_SUPER_PARTITION_SIZE=10292822016
        TARGET_QTI_DYNAMIC_PARTITIONS_SIZE=10288627712

        # ------------------------------------------
        # DVFS & SSRM Core Policy Sync (Fixes Smali Error)
        # ------------------------------------------
        # 소스 변수들을 타겟 스펙과 동기화하여 패치 툴킷의 스트링 치환 유도
        SOURCE_DVFS_CONFIG_NAME="dvfs_policy_sm8450_xx"
        SOURCE_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME="dvfs_policy_sm8450_xx"
        SOURCE_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME="siop_x800_sm8450"

        # 최종 산출물에 주입될 탭S7 세대 커널 및 SIOP 정책 파일명
        TARGET_DVFSAPP_CONFIG_DVFS_POLICY_FILENAME="dvfs_policy_sdm8250_xx"
        if [ "$TARGET_CODENAME" = "gts7xlwifi" ]; then
            TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME="siop_gts7xl_sm8250"
        else
            TARGET_DVFSAPP_CONFIG_SSRM_POLICY_FILENAME="siop_gts7l_sm8250"
        fi

        # ------------------------------------------
        # LCD & Framework Display Settings
        # ------------------------------------------
        TARGET_LCD_CONFIG_HFR_MODE="2"
        TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE="60,120"
        TARGET_LCD_CONFIG_SEAMLESS_BRT="89,91"
        TARGET_LCD_CONFIG_SEAMLESS_LUX="200,2500"
        TARGET_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION="0"
        TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS="3"
        TARGET_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE="120"
        TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL=false

        # Display Model Specific Branch (S7+ LCD Customizing)
        if [ "$TARGET_CODENAME" = "gts7xlwifi" ]; then
            TARGET_LCD_SUPPORT_MDNIE_HW=false
            TARGET_COMMON_CONFIG_MDNIE_MODE="45073"
            TARGET_COMMON_SUPPORT_HDR_EFFECT=true
            TARGET_FINGERPRINT_CONFIG_SENSOR="google_touch_display_optical,settings=3"
        else
            # 일반 탭S7 (gts7lwifi - LCD 패널 스펙 분기 안전장치)
            TARGET_LCD_SUPPORT_MDNIE_HW=true
            TARGET_COMMON_CONFIG_MDNIE_MODE="65303"
            TARGET_COMMON_SUPPORT_HDR_EFFECT=false
            TARGET_FINGERPRINT_CONFIG_SENSOR="side_button_capacitive"
        fi

        # ------------------------------------------
        # Hardware Blobs (Camera / Audio / RIL / WiFi)
        # ------------------------------------------
        # CAMERA
        TARGET_CAMERA_SUPPORT_CAMERAX_EXTENSION=true
        TARGET_CAMERA_SUPPORT_CUTOUT_PROTECTION=false
        TARGET_CAMERA_SUPPORT_MASS_APP_FLAVOR=false
        TARGET_CAMERA_SUPPORT_SDK_SERVICE=false

        # AUDIO
        TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION="07020"
        TARGET_AUDIO_SUPPORT_ACH_RINGTONE=false
        TARGET_AUDIO_SUPPORT_DUAL_SPEAKER=true
        TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION=false

        # RIL & SIM (WiFi Model Fixed)
        TARGET_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT="0"
        TARGET_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG=false
        TARGET_COMMON_SUPPORT_EMBEDDED_SIM=false

        # WIFI (Verified & Optimised)
        TARGET_WLAN_CONFIG_CONNECTION_PERSONALIZATION="0"
        TARGET_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD="100"
        TARGET_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD="0"
        TARGET_WLAN_CONFIG_DYNAMIC_SWITCH="0"
        TARGET_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD="0"
        TARGET_WLAN_SUPPORT_80211AX=true
        TARGET_WLAN_SUPPORT_80211AX_6GHZ=false
        TARGET_WLAN_SUPPORT_APE_SERVICE=false
        TARGET_WLAN_SUPPORT_LOWLATENCY=false
        TARGET_WLAN_SUPPORT_MBO=true
        TARGET_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY=false
        TARGET_WLAN_SUPPORT_MOBILEAP_6G=false
        TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE=true
        TARGET_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC=false
        TARGET_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY=false
        TARGET_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE=false
        TARGET_WLAN_SUPPORT_MOBILEAP_DUALAP=false
        TARGET_WLAN_SUPPORT_MOBILEAP_OWE=false
        TARGET_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS=true
        TARGET_WLAN_SUPPORT_TWT_CONTROL=false
        TARGET_WLAN_SUPPORT_WIFI_TO_CELLULAR=false

        # Boot Device Elements
        TARGET_OS_BOOT_DEVICE_PATH="/dev/block/by-name"
        TARGET_DISABLE_AVB_SIGNING=true
        ;;
    *)
        echo "\"$TARGET_CODENAME\" is not a valid target."
        return 1
        ;;
esac