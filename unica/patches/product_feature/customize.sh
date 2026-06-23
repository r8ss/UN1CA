#!/usr/bin/env bash

# ========================================================================================
# UN1CA Custom ROM Build Utility - Product Feature Customization Script
# Optimized for One UI 8.5+ Smali Restructuring & Dynamic Multi-Dex Mapping
# ========================================================================================

# ----------------------------------------------------------------------------------------
# Helper Functions
# ----------------------------------------------------------------------------------------

# 헬퍼 함수: 고정된 클래스 경로가 깨졌을 때 자동으로 실제 디렉터리 내부를 뒤져서 탐색
find_smali_file() {
    local target_jar="$1"     # 예: "system/framework/framework.jar"
    local fallback_path="$2"  # 기존 하드코딩 주소 (예: smali_classes4/...)
    local file_name           # 파일명 추출용
    local found

    file_name=$(basename "$fallback_path")

    # apktool 디컴파일 루트 내 실제 jar 압축 해제 폴더 내에서 검색
    local real_search_path="$APKTOOL_DIR/$target_jar"

    if [ -d "$real_search_path" ]; then
        # -print -quit으로 매칭되는 첫 파일 탐색 후 즉시 종료 (성능 최적화 및 안정성)
        found=$(find "$real_search_path" -type f -name "$file_name" -print -quit)
        if [ -n "$found" ]; then
            # APKTOOL_DIR/target_jar 부분을 떼어내고 패치 툴이 인식하는 가상 주소로 치환
            echo "${found#$APKTOOL_DIR/$target_jar/}"
            return 0
        fi
    fi
    echo "$fallback_path"
}

GET_FINGERPRINT_SENSOR_TYPE()
{
    if [[ "$1" == *"ultrasonic"* ]]; then
        echo "ultrasonic"
    elif [[ "$1" == *"optical"* ]]; then
        echo "optical"
    elif [[ "$1" == *"side"* ]]; then
        echo "side"
    else
        ABORT "Unknown fingerprint sensor type: \"$1\". Aborting"
    fi
}

LOG_MISSING_PATCHES()
{
    local MESSAGE="Missing SPF patches for condition ($1: [${!1}], $2: [${!2}])"

    if $DEBUG; then
        LOGW "$MESSAGE"
    else
        ABORT "${MESSAGE}. Aborting"
    fi
}

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_BUILD_MAINLINE_API_LEVEL
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" != "$TARGET_PRODUCT_SHIPPING_API_LEVEL" ]]; then
    target_path=$(find_smali_file "system/framework/esecomm.jar" "smali/com/sec/esecomm/EsecommAdapter.smali")
    SMALI_PATCH "system" "system/framework/esecomm.jar" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"

    target_path=$(find_smali_file "system/framework/services.jar" "smali/com/android/server/enterprise/hdm/HdmSakManager.smali")
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "isSupported(Landroid/content/Context;)Z" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"

    target_path=$(find_smali_file "system/framework/services.jar" "smali/com/android/server/enterprise/hdm/HdmVendorController.smali")
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "<init>()V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"

    target_path=$(find_smali_file "system/framework/services.jar" "smali/com/android/server/knox/dar/ddar/ta/TAProxy.smali")
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "updateServiceHolder(Z)V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"

    target_path=$(find_smali_file "system/framework/services.jar" "smali/com/android/server/SystemServer.smali")
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "startOtherServices(Lcom/android/server/utils/TimingsTraceAndSlog;)V" \
        "MAINLINE_API_LEVEL: $SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "MAINLINE_API_LEVEL: $TARGET_PRODUCT_SHIPPING_API_LEVEL"
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "startOtherServices(Lcom/android/server/utils/TimingsTraceAndSlog;)V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"

    target_path=$(find_smali_file "system/framework/services.jar" "smali_classes2/com/android/server/power/PowerManagerUtil.smali")
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"

    target_path=$(find_smali_file "system/framework/services.jar" "smali_classes2/com/android/server/sepunion/EngmodeService\$EngmodeTimeThread.smali")
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_PRODUCT_SHIPPING_API_LEVEL" \
        "$TARGET_PRODUCT_SHIPPING_API_LEVEL"
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" != "$TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" ]]; then
    if [[ "$SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" != "none" ]]; then
        target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/camera/mic/SemMultiMicManager.smali")
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "isSupported()Z" \
            "$SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" \
            "${TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION//none/}"
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "isSupported(I)Z" \
            "$SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" \
            "${TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION//none/}"
    else
        LOG_MISSING_PATCHES "SOURCE_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION" "TARGET_AUDIO_CONFIG_RECORDALIVE_LIB_VERSION"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_AUDIO_CONFIG_HAPTIC
# ----------------------------------------------------------------------------------------
if $SOURCE_AUDIO_SUPPORT_ACH_RINGTONE; then
    if ! $TARGET_AUDIO_SUPPORT_ACH_RINGTONE; then
        APPLY_PATCH "system" "system/framework/framework.jar" \
            "$MODPATH/audio/ach/framework.jar/0001-Disable-ACH-ringtone-support.patch"
    fi
else
    if $TARGET_AUDIO_SUPPORT_ACH_RINGTONE; then
        LOG_MISSING_PATCHES "SOURCE_AUDIO_SUPPORT_ACH_RINGTONE" "TARGET_AUDIO_SUPPORT_ACH_RINGTONE"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_AUDIO_SUPPORT_DUAL_SPEAKER
# ----------------------------------------------------------------------------------------
if $SOURCE_AUDIO_SUPPORT_DUAL_SPEAKER; then
    if ! $TARGET_AUDIO_SUPPORT_DUAL_SPEAKER; then
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_AUDIO_SUPPORT_DUAL_SPEAKER" --delete

        APPLY_PATCH "system" "system/framework/framework.jar" \
            "$MODPATH/audio/dual_speaker/framework.jar/0001-Disable-dual-speaker-support.patch"
        APPLY_PATCH "system" "system/framework/services.jar" \
            "$MODPATH/audio/dual_speaker/services.jar/0001-Disable-dual-speaker-support.patch"
    fi
else
    if $TARGET_AUDIO_SUPPORT_DUAL_SPEAKER; then
        LOG_MISSING_PATCHES "SOURCE_AUDIO_SUPPORT_DUAL_SPEAKER" "TARGET_AUDIO_SUPPORT_DUAL_SPEAKER"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_AUDIO_SUPPORT_VIRTUAL_VIBRATION_SOUND
# ----------------------------------------------------------------------------------------
if $SOURCE_AUDIO_SUPPORT_VIRTUAL_VIBRATION; then
    if ! $TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION; then
        APPLY_PATCH "system" "system/framework/framework.jar" \
            "$MODPATH/audio/virtual_vib/framework.jar/0001-Disable-virtual-vibration-support.patch"
        APPLY_PATCH "system" "system/framework/services.jar" \
            "$MODPATH/audio/virtual_vib/services.jar/0001-Disable-virtual-vibration-support.patch"

        target_path=$(find_smali_file "system/framework/services.jar" "smali/com/android/server/audio/BtHelper\$\$ExternalSyntheticLambda0.smali")
        SMALI_PATCH "system" "system/framework/services.jar" \
            "$target_path" "remove"

        target_path=$(find_smali_file "system/framework/services.jar" "smali_classes2/com/android/server/vibrator/VibratorManagerInternal.smali")
        sed -i "/.source/q" "$APKTOOL_DIR/system/framework/services.jar/$target_path"

        target_path=$(find_smali_file "system/framework/services.jar" "smali_classes2/com/android/server/vibrator/VibratorManagerService\$SamsungBroadcastReceiver\$\$ExternalSyntheticLambda1.smali")
        SMALI_PATCH "system" "system/framework/services.jar" \
            "$target_path" "remove"

        target_path=$(find_smali_file "system/framework/services.jar" "smali_classes2/com/android/server/vibrator/VirtualVibSoundHelper.smali")
        SMALI_PATCH "system" "system/framework/services.jar" \
            "$target_path" "remove"

        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$MODPATH/audio/virtual_vib/SecSettings.apk/0001-Disable-virtual-vibration-support.patch"
        APPLY_PATCH "system" "system/priv-app/SettingsProvider/SettingsProvider.apk" \
            "$MODPATH/audio/virtual_vib/SettingsProvider.apk/0001-Disable-virtual-vibration-support.patch"
    fi
else
    if $TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION; then
        LOG_MISSING_PATCHES "SOURCE_AUDIO_SUPPORT_VIRTUAL_VIBRATION" "TARGET_AUDIO_SUPPORT_VIRTUAL_VIBRATION"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_COMMON_CONFIG_MDNIE_MODE
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_COMMON_CONFIG_MDNIE_MODE" != "$TARGET_COMMON_CONFIG_MDNIE_MODE" ]]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_MDNIE_MODE" "$TARGET_COMMON_CONFIG_MDNIE_MODE"

    target_path=$(find_smali_file "system/framework/services.jar" "smali_classes2/com/samsung/android/hardware/display/SemMdnieManagerService.smali")
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "<init>(Landroid/content/Context;)V" \
        "$SOURCE_COMMON_CONFIG_MDNIE_MODE" \
        "$TARGET_COMMON_CONFIG_MDNIE_MODE"
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_COMMON_CONFIG_DYN_RESOLUTION_CONTROL
# ----------------------------------------------------------------------------------------
if ! $SOURCE_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
    if $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
        if [[ "$(GET_FINGERPRINT_SENSOR_TYPE "$TARGET_FINGERPRINT_CONFIG_SENSOR")" == "optical" ]]; then
            ABORT "TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL is not supported on targets with an optical fingerprint sensor"
        fi

        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_DYN_RESOLUTION_CONTROL" "WQHD,FHD,HD"

        # 인라인 평가식 안정성 보정
        local ssi_target="b0sxxx"
        [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && ssi_target="b0qxxx"

        ADD_TO_WORK_DIR "$ssi_target" "system" "system/bin/bootanimation" 0 2000 755 "u:object_r:bootanim_exec:s0"
        ADD_TO_WORK_DIR "$ssi_target" "system" "system/bin/surfaceflinger" 0 2000 755 "u:object_r:surfaceflinger_exec:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/battery_error.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/battery_low.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/battery_protection.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/battery_temperature_error.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/battery_temperature_limit.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/battery_water_usb.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/incomplete_connect.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/lcd_density.txt" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_0_100.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_1_100.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_2_100.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_0_1.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_0_2.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_0_3.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_0_4.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_1_1.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_1_2.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_1_3.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_1_4.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_2_1.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_2_2.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_2_3.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/new_vi_level_2_4.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/slow_charging_usb.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/temperature_limit_usb.spi" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" "system/media/water_protection_usb.spi" 0 0 644 "u:object_r:system_file:s0"

        if [ "$TARGET_PLATFORM_SDK_VERSION" -ge "36" ]; then
            APPLY_PATCH "system" "system/framework/framework.jar" \
                "$MODPATH/resolution/framework.jar/0001-Enable-FW_SUPPORT_MULTI_RESOLUTION.patch"
        else
            APPLY_PATCH "system" "system/framework/framework.jar" \
                "$MODPATH/resolution/framework.jar/0001-Enable-FW_DYNAMIC_RESOLUTION_CONTROL.patch"
        fi
        APPLY_PATCH "system" "system/framework/gamemanager.jar" \
            "$MODPATH/resolution/gamemanager.jar/0001-Enable-dynamic-resolution-control.patch"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$MODPATH/resolution/SecSettings.apk/0001-Enable-dynamic-resolution-control.patch"

        target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes2/com/android/settings/Utils\$\$ExternalSyntheticLambda2.smali")
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$target_path" "remove"

        target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes2/com/android/settings/Utils\$\$ExternalSyntheticLambda3.smali")
        sed -i "s/^\.implements.*/.implements Landroidx\/core\/view\/OnApplyWindowInsetsListener;/g" "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$target_path"

        target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes2/com/android/settings/applications/manageapplications/ManageApplications\$ApplicationsAdapter\$\$ExternalSyntheticLambda3.smali")
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$target_path" "remove"

        target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes2/com/android/settings/applications/manageapplications/ManageApplications\$ApplicationsAdapter\$\$ExternalSyntheticLambda7.smali")
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$target_path" "remove"

        target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes2/com/android/settings/applications/manageapplications/ManageApplications\$ApplicationsAdapter\$\$ExternalSyntheticLambda9.smali")
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$target_path" "remove"

        target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes2/com/android/settings/applications/manageapplications/ManageApplications\$ApplicationsAdapter\$\$ExternalSyntheticOutline0.smali")
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$target_path" "remove"

        if [ "$TARGET_PLATFORM_SDK_VERSION" -lt "36" ]; then
            APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                "$MODPATH/resolution/SecSettings.apk/0002-Backport-legacy-DYN_RESOLUTION_CONTROL-code.patch"

            target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/display/ScreenResolutionFragment.smali")
            sed -i "/static fields/,+3d" "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$target_path"

            target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/display/controller/ScreenResolutionPreferenceController\$2.smali")
            SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                "$target_path" "remove"
        fi
        APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
            "$MODPATH/resolution/SystemUI.apk/0001-Enable-dynamic-resolution-control.patch"
    fi
else
    if ! $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
        LOG_MISSING_PATCHES "SOURCE_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL" "TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_COMMON_SUPPORT_EMBEDDED_SIM
# ----------------------------------------------------------------------------------------
if $SOURCE_COMMON_SUPPORT_EMBEDDED_SIM; then
    if ! $TARGET_COMMON_SUPPORT_EMBEDDED_SIM; then
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_EMBEDDED_SIM_SLOTSWITCH" --delete
    fi
else
    if $TARGET_COMMON_SUPPORT_EMBEDDED_SIM; then
        LOG_MISSING_PATCHES "SOURCE_COMMON_SUPPORT_EMBEDDED_SIM" "TARGET_COMMON_SUPPORT_EMBEDDED_SIM"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_COMMON_SUPPORT_HDR_EFFECT
# ----------------------------------------------------------------------------------------
if $SOURCE_COMMON_SUPPORT_HDR_EFFECT; then
    if ! $TARGET_COMMON_SUPPORT_HDR_EFFECT; then
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_HDR_EFFECT" --delete

        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$MODPATH/mdnie/hdr/SecSettings.apk/0001-Disable-HDR-Settings.patch"
        APPLY_PATCH "system" "system/priv-app/SettingsProvider/SettingsProvider.apk" \
            "$MODPATH/mdnie/hdr/SettingsProvider.apk/0001-Disable-HDR-Settings.patch"
    else
        if [ ! "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_HDR_EFFECT")" ]; then
            SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_SUPPORT_HDR_EFFECT" "TRUE"
        fi
    fi
else
    if $TARGET_COMMON_SUPPORT_HDR_EFFECT; then
        LOG_MISSING_PATCHES "SOURCE_COMMON_SUPPORT_HDR_EFFECT" "TARGET_COMMON_SUPPORT_HDR_EFFECT"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_FINGERPRINT_CONFIG_SENSOR
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_FINGERPRINT_CONFIG_SENSOR" != "$TARGET_FINGERPRINT_CONFIG_SENSOR" ]]; then
    # 패치 전 원본 소스 캐싱 확보 (변수 오염 방지)
    local _src_sensor_orig="$SOURCE_FINGERPRINT_CONFIG_SENSOR"

    target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/bio/fingerprint/SemFingerprintManager.smali")
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "$target_path" "replace" \
        "getMaxTemplateNumberFromSPF()I" \
        "$_src_sensor_orig" \
        "$TARGET_FINGERPRINT_CONFIG_SENSOR"
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "$target_path" "replace" \
        "getProductFeatureValue(Landroid/content/Context;)Ljava/lang/String;" \
        "$_src_sensor_orig" \
        "$TARGET_FINGERPRINT_CONFIG_SENSOR"

    target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/bio/fingerprint/SemFingerprintManager\$Characteristics.smali")
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "$target_path" "replaceall" \
        "$_src_sensor_orig" \
        "$TARGET_FINGERPRINT_CONFIG_SENSOR"

    target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/biometrics/fingerprint/FingerprintSettingsUtils.smali")
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$target_path" "replaceall" \
        "$_src_sensor_orig" \
        "$TARGET_FINGERPRINT_CONFIG_SENSOR"

    if [[ "$(GET_FINGERPRINT_SENSOR_TYPE "$_src_sensor_orig")" != "$(GET_FINGERPRINT_SENSOR_TYPE "$TARGET_FINGERPRINT_CONFIG_SENSOR")" ]]; then
        if [[ "$(GET_FINGERPRINT_SENSOR_TYPE "$_src_sensor_orig")" == "ultrasonic" ]]; then
            if [[ "$(GET_FINGERPRINT_SENSOR_TYPE "$TARGET_FINGERPRINT_CONFIG_SENSOR")" == "optical" ]]; then
                SOURCE_FINGERPRINT_CONFIG_SENSOR="google_touch_display_optical,settings=3"

                if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
                    ADD_TO_WORK_DIR "r9qxxx" "system" "system/bin/surfaceflinger" 0 2000 755 "u:object_r:surfaceflinger_exec:s0"
                    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libgui.so" 0 0 644 "u:object_r:system_lib_file:s0"
                    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib/libui.so" 0 0 644 "u:object_r:system_lib_file:s0"
                    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib64/libgui.so" 0 0 644 "u:object_r:system_lib_file:s0"
                    ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib64/libui.so" 0 0 644 "u:object_r:system_lib_file:s0"
                elif [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "essi" ]]; then
                    ADD_TO_WORK_DIR "r9sxxx" "system" "system/bin/surfaceflinger" 0 2000 755 "u:object_r:surfaceflinger_exec:s0"
                    ADD_TO_WORK_DIR "r9sxxx" "system" "system/lib/libgui.so" 0 0 644 "u:object_r:system_lib_file:s0"
                    ADD_TO_WORK_DIR "r9sxxx" "system" "system/lib/libui.so" 0 0 644 "u:object_r:system_lib_file:s0"
                    ADD_TO_WORK_DIR "r9sxxx" "system" "system/lib64/libgui.so" 0 0 644 "u:object_r:system_lib_file:s0"
                    ADD_TO_WORK_DIR "r9sxxx" "system" "system/lib64/libui.so" 0 0 644 "u:object_r:system_lib_file:s0"
                else
                    ABORT "Unknown SSI: $TARGET_OS_SINGLE_SYSTEM_IMAGE"
                fi

                ADD_TO_WORK_DIR "r9qxxx" "system" "system/priv-app/BiometricSetting/BiometricSetting.apk" 0 0 644 "u:object_r:system_file:s0"

                APPLY_PATCH "system" "system/framework/framework.jar" \
                    "$MODPATH/fingerprint/optical_fod/framework.jar/0001-Add-optical-FOD-support.patch"
                APPLY_PATCH "system" "system/framework/services.jar" \
                    "$MODPATH/fingerprint/optical_fod/services.jar/0001-Add-optical-FOD-support.patch"
                APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                    "$MODPATH/fingerprint/optical_fod/SecSettings.apk/0001-Add-optical-FOD-support.patch"
                APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
                    "$MODPATH/fingerprint/optical_fod/SystemUI.apk/0001-Add-optical-FOD-support.patch"

                if [[ "$TARGET_FINGERPRINT_CONFIG_SENSOR" == *"no_delay_in_screen_off"* ]]; then
                    APPLY_PATCH "system" "system/priv-app/BiometricSetting/BiometricSetting.apk" \
                        "$MODPATH/fingerprint/optical_fod/BiometricSetting.apk/0001-Enable-FP_FEATURE_NO_DELAY_IN_SCREEN_OFF.patch"
                fi

                if [[ "$TARGET_FINGERPRINT_CONFIG_SENSOR" == *"transition_effect_on"* ]]; then
                    target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes2/android/hardware/fingerprint/FingerprintManager.smali")
                    SMALI_PATCH "system" "system/framework/framework.jar" \
                        "$target_path" "return" \
                        "semGetTransitionEffectValue()I" \
                        "1"
                elif [[ "$TARGET_FINGERPRINT_CONFIG_SENSOR" == *"transition_effect_off"* ]]; then
                    target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes2/android/hardware/fingerprint/FingerprintManager.smali")
                    SMALI_PATCH "system" "system/framework/framework.jar" \
                        "$target_path" "return" \
                        "semGetTransitionEffectValue()I" \
                        "0"
                fi
            elif [[ "$(GET_FINGERPRINT_SENSOR_TYPE "$TARGET_FINGERPRINT_CONFIG_SENSOR")" == "side" ]]; then
                SOURCE_FINGERPRINT_CONFIG_SENSOR="google_touch_side,navi=1"

                ADD_TO_WORK_DIR "b4qxxx" "system" "system/priv-app/BiometricSetting/BiometricSetting.apk" 0 0 644 "u:object_r:system_file:s0"
                APPLY_PATCH "system" "system/priv-app/BiometricSetting/BiometricSetting.apk" \
                    "$MODPATH/fingerprint/side_fp/BiometricSetting.apk/0001-Add-FEATURE_FINGERPRINT_JDM_HAL-support.patch"

                APPLY_PATCH "system" "system/framework/framework.jar" \
                    "$MODPATH/fingerprint/side_fp/framework.jar/0001-Add-side-fingerprint-sensor-support.patch"
                APPLY_PATCH "system" "system/framework/services.jar" \
                    "$MODPATH/fingerprint/side_fp/services.jar/0001-Add-side-fingerprint-sensor-support.patch"

                target_path=$(find_smali_file "system/framework/services.jar" "smali/com/android/server/biometrics/sensors/fingerprint/SemFingerprintServiceExtImpl.smali")
                sed -i "/implements/i .implements Lcom\/android\/server\/biometrics\/sensors\/fingerprint\/SemFpHalLifecycleListener;" "$APKTOOL_DIR/system/framework/services.jar/$target_path"

                APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                    "$MODPATH/fingerprint/side_fp/SecSettings.apk/0001-Add-side-fingerprint-sensor-support.patch"

                target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/biometrics/fingerprint/SuwFingerprintUsefulFeature\$\$ExternalSyntheticLambda1.smali")
                sed -i "s/^\.implements.*/.implements Landroid\/widget\/CompoundButton\$OnCheckedChangeListener;/g" "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$target_path"

                target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/biometrics/fingerprint/SuwFingerprintUsefulFeature\$\$ExternalSyntheticLambda4.smali")
                SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                    "$target_path" "remove"

                target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/biometrics/fingerprint/SuwFingerprintUsefulFeature\$\$ExternalSyntheticLambda9.smali")
                SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                    "$target_path" "remove"

                target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/biometrics/fingerprint/SuwFingerprintUsefulFeature\$1.smali")
                SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                    "$target_path" "remove"

                APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
                    "$MODPATH/fingerprint/side_fp/SystemUI.apk/0001-Add-side-fingerprint-sensor-support.patch"

                target_path=$(find_smali_file "system_ext" "priv-app/SystemUI/SystemUI.apk" "smali/com/android/systemui/keyguard/KeyguardSecUpdateMonitorImpl\$\$ExternalSyntheticLambda28.smali")
                sed -i "s/^\.implements.*/.implements Ljava\/util\/function\/Consumer;/g" "$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk/$target_path"

                target_path=$(find_smali_file "system_ext" "priv-app/SystemUI/SystemUI.apk" "smali/com/android/systemui/keyguard/KeyguardSecUpdateMonitorImpl\$\$ExternalSyntheticLambda24.smali")
                SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$target_path" "remove"

                target_path=$(find_smali_file "system_ext" "priv-app/SystemUI/SystemUI.apk" "smali/com/android/systemui/keyguard/KeyguardSecUpdateMonitorImpl\$\$ExternalSyntheticLambda29.smali")
                SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$target_path" "remove"

                target_path=$(find_smali_file "system_ext" "priv-app/SystemUI/SystemUI.apk" "smali/com/android/systemui/keyguard/KeyguardSecUpdateMonitorImpl\$\$ExternalSyntheticLambda33.smali")
                SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$target_path" "remove"

                target_path=$(find_smali_file "system_ext" "priv-app/SystemUI/SystemUI.apk" "smali/com/android/systemui/keyguard/KeyguardSecUpdateMonitorImpl\$\$ExternalSyntheticLambda40.smali")
                SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$target_path" "remove"

                target_path=$(find_smali_file "system_ext" "priv-app/SystemUI/SystemUI.apk" "smali/com/android/systemui/keyguard/KeyguardSecUpdateMonitorImpl\$\$ExternalSyntheticLambda42.smali")
                SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" "$target_path" "remove"

                target_path=$(find_smali_file "system/framework/services.jar" "smali/com/android/server/biometrics/SemBiometricFeature.smali")
                if [[ "$TARGET_FINGERPRINT_CONFIG_SENSOR" == *"navi=1"* ]]; then
                    LOG "- Enabling FP_FEATURE_GESTURE_MODE:Z in $target_path"
                    SMALI_PATCH "system" "system/framework/services.jar" \
                        "$target_path" "replace" \
                        "<clinit>()V" \
                        "sput-boolean v3, Lcom/android/server/biometrics/SemBiometricFeature;->FP_FEATURE_GESTURE_MODE:Z" \
                        "sput-boolean v2, Lcom/android/server/biometrics/SemBiometricFeature;->FP_FEATURE_GESTURE_MODE:Z" \
                        > /dev/null
                fi
                if [[ "$TARGET_FINGERPRINT_CONFIG_SENSOR" == *"swipe_enroll"* ]]; then
                    LOG "- Enabling FP_FEATURE_SWIPE_ENROLL:Z in $target_path"
                    SMALI_PATCH "system" "system/framework/services.jar" \
                        "$target_path" "replace" \
                        "<clinit>()V" \
                        "sput-boolean v3, Lcom/android/server/biometrics/SemBiometricFeature;->FP_FEATURE_SWIPE_ENROLL:Z" \
                        "sput-boolean v2, Lcom/android/server/biometrics/SemBiometricFeature;->FP_FEATURE_SWIPE_ENROLL:Z" \
                        > /dev/null
                fi
                if [[ "$TARGET_FINGERPRINT_CONFIG_SENSOR" == *"wof_off"* ]]; then
                    LOG "- Enabling FP_FEATURE_WOF_OPTION_DEFAULT_OFF:Z in $target_path"
                    SMALI_PATCH "system" "system/framework/services.jar" \
                        "$target_path" "replace" \
                        "<clinit>()V" \
                        "sput-boolean v3, Lcom/android/server/biometrics/SemBiometricFeature;->FP_FEATURE_WOF_OPTION_DEFAULT_OFF:Z" \
                        "sput-boolean v2, Lcom/android/server/biometrics/SemBiometricFeature;->FP_FEATURE_WOF_OPTION_DEFAULT_OFF:Z" \
                        > /dev/null
                fi
            elif [[ "$(GET_FINGERPRINT_SENSOR_TYPE "$TARGET_FINGERPRINT_CONFIG_SENSOR")" != "ultrasonic" ]]; then
                LOG_MISSING_PATCHES "SOURCE_FINGERPRINT_CONFIG_SENSOR" "TARGET_FINGERPRINT_CONFIG_SENSOR"
            fi
        else
            LOG_MISSING_PATCHES "SOURCE_FINGERPRINT_CONFIG_SENSOR" "TARGET_FINGERPRINT_CONFIG_SENSOR"
        fi
    fi

    if [[ "$_src_sensor_orig" != "$TARGET_FINGERPRINT_CONFIG_SENSOR" ]]; then
        target_path=$(find_smali_file "system/priv-app/BiometricSetting/BiometricSetting.apk" "smali/com/samsung/android/biometrics/app/setting/DisplayStateManager.smali")
        SMALI_PATCH "system" "system/priv-app/BiometricSetting/BiometricSetting.apk" \
            "$target_path" "replace" \
            "<init>(Lcom/samsung/android/biometrics/app/setting/BiometricsUIService;)V" \
            "$_src_sensor_orig" \
            "$TARGET_FINGERPRINT_CONFIG_SENSOR"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" != "$TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" ]]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" "$TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS"

    target_path=$(find_smali_file "system/framework/services.jar" "smali_classes2/com/android/server/power/PowerManagerUtil.smali")
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" \
        "$TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS"

    target_path=$(find_smali_file "system/framework/ssrm.jar" "smali/com/android/server/ssrm/PreMonitor.smali")
    SMALI_PATCH "system" "system/framework/ssrm.jar" \
        "$target_path" "replace" \
        "getBrightness()Ljava/lang/String;" \
        "$SOURCE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" \
        "$TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS"

    target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/Rune.smali")
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS" \
        "$TARGET_LCD_CONFIG_CONTROL_AUTO_BRIGHTNESS"
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_LCD_CONFIG_SEAMLESS_BRT & SEC_PRODUCT_FEATURE_LCD_CONFIG_SEAMLESS_LUX
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_LCD_CONFIG_SEAMLESS_BRT" != "$TARGET_LCD_CONFIG_SEAMLESS_BRT" ]] || \
        [[ "$SOURCE_LCD_CONFIG_SEAMLESS_LUX" != "$TARGET_LCD_CONFIG_SEAMLESS_LUX" ]]; then
    if [[ "$SOURCE_LCD_CONFIG_SEAMLESS_BRT" != "none" ]] && [[ "$SOURCE_LCD_CONFIG_SEAMLESS_LUX" != "none" ]] && \
            [[ "$TARGET_LCD_CONFIG_SEAMLESS_BRT" == "none" ]] && [[ "$TARGET_LCD_CONFIG_SEAMLESS_LUX" == "none" ]]; then
        APPLY_PATCH "system" "system/framework/framework.jar" \
            "$MODPATH/hfr/framework.jar/0001-Remove-brightness-threshold-values.patch"
    elif [[ "$SOURCE_LCD_CONFIG_SEAMLESS_BRT" != "none" ]] && [[ "$SOURCE_LCD_CONFIG_SEAMLESS_LUX" != "none" ]] && \
            [[ "$TARGET_LCD_CONFIG_SEAMLESS_BRT" != "none" ]] && [[ "$TARGET_LCD_CONFIG_SEAMLESS_LUX" != "none" ]]; then

        target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali")
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "dump(Ljava/io/PrintWriter;Ljava/lang/String;Z)V" \
            "SEAMLESS_BRT: $SOURCE_LCD_CONFIG_SEAMLESS_BRT" \
            "SEAMLESS_BRT: $TARGET_LCD_CONFIG_SEAMLESS_BRT"
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "dump(Ljava/io/PrintWriter;Ljava/lang/String;Z)V" \
            "SEAMLESS_LUX: $SOURCE_LCD_CONFIG_SEAMLESS_LUX" \
            "SEAMLESS_LUX: $TARGET_LCD_CONFIG_SEAMLESS_LUX"
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "getMainInstance()Lcom/samsung/android/hardware/display/RefreshRateConfig;" \
            "$SOURCE_LCD_CONFIG_SEAMLESS_BRT" \
            "$TARGET_LCD_CONFIG_SEAMLESS_BRT"
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "getMainInstance()Lcom/samsung/android/hardware/display/RefreshRateConfig;" \
            "$SOURCE_LCD_CONFIG_SEAMLESS_LUX" \
            "$TARGET_LCD_CONFIG_SEAMLESS_LUX"
    else
        LOG_MISSING_PATCHES "SOURCE_LCD_CONFIG_SEAMLESS_BRT" "TARGET_LCD_CONFIG_SEAMLESS_BRT" || true
        LOG_MISSING_PATCHES "SOURCE_LCD_CONFIG_SEAMLESS_LUX" "TARGET_LCD_CONFIG_SEAMLESS_LUX"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" != "$TARGET_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" ]]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" "$TARGET_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE"

    target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali")
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "$target_path" "replace" \
        "dump(Ljava/io/PrintWriter;Ljava/lang/String;Z)V" \
        "HFR_DEFAULT_REFRESH_RATE: $SOURCE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" \
        "HFR_DEFAULT_REFRESH_RATE: $TARGET_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE"

    target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali")
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$target_path" "replace" \
        "getHighRefreshRateDefaultValue(Landroid/content/Context;I)I" \
        "$SOURCE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" \
        "$TARGET_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE"

    target_path=$(find_smali_file "system/priv-app/SettingsProvider/SettingsProvider.apk" "smali/com/android/providers/settings/DatabaseHelper.smali")
    SMALI_PATCH "system" "system/priv-app/SettingsProvider/SettingsProvider.apk" \
        "$target_path" "replace" \
        "loadRefreshRateMode(Landroid/database/sqlite/SQLiteStatement;Ljava/lang/String;)V" \
        "$SOURCE_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE" \
        "$TARGET_LCD_CONFIG_HFR_DEFAULT_REFRESH_RATE"
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_LCD_CONFIG_HFR_MODE
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_LCD_CONFIG_HFR_MODE" != "$TARGET_LCD_CONFIG_HFR_MODE" ]]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_MODE" "$TARGET_LCD_CONFIG_HFR_MODE"

    target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes2/android/inputmethodservice/SemImsRune.smali")
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"

    target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali")
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "$target_path" "replace" \
        "dump(Ljava/io/PrintWriter;Ljava/lang/String;Z)V" \
        "HFR_MODE: $SOURCE_LCD_CONFIG_HFR_MODE" \
        "HFR_MODE: $TARGET_LCD_CONFIG_HFR_MODE"
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "$target_path" "replace" \
        "getMainInstance()Lcom/samsung/android/hardware/display/RefreshRateConfig;" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"

    target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/rune/CoreRune.smali")
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"

    target_path=$(find_smali_file "system/framework/gamemanager.jar" "smali/com/samsung/android/game/GameManagerService.smali")
    SMALI_PATCH "system" "system/framework/gamemanager.jar" \
        "$target_path" "replace" \
        "isVariableRefreshRateSupported()Ljava/lang/String;" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"

    target_path=$(find_smali_file "system/framework/secinputdev-service.jar" "smali/com/samsung/android/hardware/secinputdev/utils/SemInputFeatures.smali")
    SMALI_PATCH "system" "system/framework/secinputdev-service.jar" \
        "$target_path" "replaceall" \
        "\"$SOURCE_LCD_CONFIG_HFR_MODE\"" \
        "\"$TARGET_LCD_CONFIG_HFR_MODE\""

    target_path=$(find_smali_file "system/framework/secinputdev-service.jar" "smali/com/samsung/android/hardware/secinputdev/utils/SemInputFeaturesExtra.smali")
    SMALI_PATCH "system" "system/framework/secinputdev-service.jar" \
        "$target_path" "replaceall" \
        "\"$SOURCE_LCD_CONFIG_HFR_MODE\"" \
        "\"$TARGET_LCD_CONFIG_HFR_MODE\""

    target_path=$(find_smali_file "system/framework/services.jar" "smali_classes2/com/android/server/power/PowerManagerUtil.smali")
    SMALI_PATCH "system" "system/framework/services.jar" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"

    target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali")
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$target_path" "replace" \
        "getHighRefreshRateSeamlessType(I)I" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$target_path" "replace" \
        "isSupportMaxHS60RefreshRate(I)Z" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"

    target_path=$(find_smali_file "system/priv-app/SettingsProvider/SettingsProvider.apk" "smali/com/android/providers/settings/DatabaseHelper.smali")
    SMALI_PATCH "system" "system/priv-app/SettingsProvider/SettingsProvider.apk" \
        "$target_path" "replace" \
        "loadRefreshRateMode(Landroid/database/sqlite/SQLiteStatement;Ljava/lang/String;)V" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"

    target_path=$(find_smali_file "system_ext" "priv-app/SystemUI/SystemUI.apk" "smali/com/android/systemui/BasicRune.smali")
    SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"

    target_path=$(find_smali_file "system_ext" "priv-app/SystemUI/SystemUI.apk" "smali/com/android/systemui/LsRune.smali")
    SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
        "$target_path" "replace" \
        "<clinit>()V" \
        "$SOURCE_LCD_CONFIG_HFR_MODE" \
        "$TARGET_LCD_CONFIG_HFR_MODE"
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" != "$TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" ]]; then
    if [[ "$TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" != "none" ]]; then
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" "$TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE"
    else
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" "0"
    fi

    if [[ "$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" != "none" ]]; then
        target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali")
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "dump(Ljava/io/PrintWriter;Ljava/lang/String;Z)V" \
            "HFR_SUPPORTED_REFRESH_RATE: $SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" \
            "HFR_SUPPORTED_REFRESH_RATE: ${TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE//none/}"
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "getMainInstance()Lcom/samsung/android/hardware/display/RefreshRateConfig;" \
            "$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" \
            "${TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE//none/}"

        target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali")
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$target_path" "replace" \
            "getHighRefreshRateSupportedValues(I)[Ljava/lang/String;" \
            "$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" \
            "${TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE//none/}"

        target_path=$(find_smali_file "system_ext" "priv-app/SystemUI/SystemUI.apk" "smali_classes2/com/android/systemui/keyguard/KeyguardViewMediatorHelperImpl\$\$ExternalSyntheticLambda0.smali")
        SMALI_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
            "$target_path" "replace" \
            "invoke()Ljava/lang/Object;" \
            "$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" \
            "${TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE//none/}"
    else
        LOG_MISSING_PATCHES "SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE" "TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" != "$TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" ]]; then
    if [[ "$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" != "none" ]]; then
        if [[ "$TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" != "none" ]]; then
            SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" "$TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS"
        else
            SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" --delete
        fi

        target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali")
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "dump(Ljava/io/PrintWriter;Ljava/lang/String;Z)V" \
            "HFR_SUPPORTED_REFRESH_RATE_NS: $SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" \
            "HFR_SUPPORTED_REFRESH_RATE_NS: ${TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS//none/}"
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replace" \
            "getMainInstance()Lcom/samsung/android/hardware/display/RefreshRateConfig;" \
            "$SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" \
            "${TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS//none/}"
    else
        LOG_MISSING_PATCHES "SOURCE_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS" "TARGET_LCD_CONFIG_HFR_SUPPORTED_REFRESH_RATE_NS"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_LCD_SUPPORT_MDNIE_HW & SEC_PRODUCT_FEATURE_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION
# ----------------------------------------------------------------------------------------
if $SOURCE_LCD_SUPPORT_MDNIE_HW && [[ "$SOURCE_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION" != "0" ]]; then
    if ! $TARGET_LCD_SUPPORT_MDNIE_HW; then
        SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_SUPPORT_MDNIE_HW" --delete

        APPLY_PATCH "system" "system/framework/framework.jar" \
            "$MODPATH/mdnie/hw/framework.jar/0001-Disable-HW-mDNIe.patch"
        if [[ "$TARGET_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION" == "0" ]]; then
            APPLY_PATCH "system" "system/framework/framework.jar" \
                "$MODPATH/mdnie/hw/framework.jar/0002-Disable-A11Y_COLOR_BOOL_SUPPORT_DMC_COLORWEAKNESS.patch"
        fi
        APPLY_PATCH "system" "system/framework/services.jar" \
            "$MODPATH/mdnie/hw/services.jar/0001-Disable-HW-mDNIe.patch"
    fi
elif $SOURCE_LCD_SUPPORT_MDNIE_HW && [[ "$SOURCE_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION" == "0" ]]; then
    LOG_MISSING_PATCHES "SOURCE_LCD_SUPPORT_MDNIE_HW" "TARGET_LCD_SUPPORT_MDNIE_HW" || true
    LOG_MISSING_PATCHES "SOURCE_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION" "TARGET_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION"
else
    if $TARGET_LCD_SUPPORT_MDNIE_HW || \
            [[ "$SOURCE_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION" != "$TARGET_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION" ]]; then
        LOG_MISSING_PATCHES "SOURCE_LCD_SUPPORT_MDNIE_HW" "TARGET_LCD_SUPPORT_MDNIE_HW" || true
        LOG_MISSING_PATCHES "SOURCE_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION" "TARGET_LCD_CONFIG_COLOR_WEAKNESS_SOLUTION"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_RIL_FEATURES
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_RIL_FEATURES" != "$TARGET_RIL_FEATURES" ]]; then
    if [[ "$SOURCE_RIL_FEATURES" != "none" ]]; then
        # One UI 8.5 구조 동적 매핑 보정
        target_path=$(find_smali_file "system/framework/framework.jar" "smali/com/android/internal/telephony/TelephonyFeatures.smali")
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "replaceall" \
            "$SOURCE_RIL_FEATURES" \
            "${TARGET_RIL_FEATURES//none/}"

        target_path=$(find_smali_file "system/framework/telephony-common.jar" "smali/com/android/internal/telephony/TelephonyLogger.smali")
        SMALI_PATCH "system" "system/framework/telephony-common.jar" \
            "$target_path" "replace" \
            "dump(Ljava/io/FileDescriptor;Ljava/io/PrintWriter;[Ljava/lang/String;)V" \
            "$SOURCE_RIL_FEATURES" \
            "${TARGET_RIL_FEATURES//none/}"

        target_path=$(find_smali_file "system/priv-app/TeleService/TeleService.apk" "smali/com/samsung/telephony/model/feature/tag/SamsungProductFeatureTag.smali")
        SMALI_PATCH "system" "system/priv-app/TeleService/TeleService.apk" \
            "$target_path" "replaceall" \
            "$SOURCE_RIL_FEATURES" \
            "${TARGET_RIL_FEATURES//none/}"

        target_path=$(find_smali_file "system/priv-app/TeleService/TeleService.apk" "smali/com/samsung/telephony/model/feature/SamsungFeatureSatellite.smali")
        SMALI_PATCH "system" "system/priv-app/TeleService/TeleService.apk" \
            "$target_path" "replaceall" \
            "$SOURCE_RIL_FEATURES" \
            "${TARGET_RIL_FEATURES//none/}"
    else
        LOG_MISSING_PATCHES "SOURCE_RIL_FEATURES" "TARGET_RIL_FEATURES"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT" != "$TARGET_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT" ]]; then
    if [[ "$SOURCE_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT" == "1" ]] && \
            [[ "$TARGET_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT" != "1" ]]; then
        target_path=$(find_smali_file "system/framework/framework.jar" "smali/com/android/internal/telephony/TelephonyFeatures.smali")
        SMALI_PATCH "system" "system/framework/framework.jar" \
            "$target_path" "return" \
            "isOneTray()Z" \
            "false"
    elif [[ "$SOURCE_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT" != "1" ]] && \
            [[ "$TARGET_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT" == "1" ]]; then
        LOG_MISSING_PATCHES "SOURCE_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT" "TARGET_RIL_SIM_CONFIG_MULTISIM_TRAYCOUNT"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG
# ----------------------------------------------------------------------------------------
if $SOURCE_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG; then
    if ! $TARGET_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG; then
        APPLY_PATCH "system" "system/framework/telephony-common.jar" \
            "$MODPATH/ril/telephony-common.jar/0001-Disable-RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG.patch"
    fi
else
    if $TARGET_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG; then
        LOG_MISSING_PATCHES "SOURCE_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG" "TARGET_RIL_SUPPORT_WATERPROOF_SIM_TRAY_MSG"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_SECURITY_SUPPORT_STRONGBOX
# ----------------------------------------------------------------------------------------
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

if [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/vendor/etc/permissions/android.hardware.strongbox_keystore.xml" ]; then
    target_path=$(find_smali_file "system/framework/framework.jar" "smali_classes6/com/samsung/android/service/DeviceIDProvisionService/DeviceIDProvisionManager\$DeviceIDProvisionWorker.smali")
    SMALI_PATCH "system" "system/framework/framework.jar" \
        "$target_path" "return" \
        "isSupportStrongboxDeviceID()Z" \
        "false"
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD" != "$TARGET_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD" ]] || \
        [[ "$SOURCE_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD" != "$TARGET_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD" ]] || \
        [[ "$SOURCE_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD" != "$TARGET_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD" ]]; then
    if [[ "$SOURCE_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD" == "100" ]] && \
            [[ "$SOURCE_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD" == "0" ]] && \
            [[ "$SOURCE_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD" == "0" ]]; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/thresholds/semwifi-service.jar/0001-Allow-custom-booster-thresholds-values.patch"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali")

        # sed 인라인 치환 방식으로 완전히 로직 분리 및 안정화
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replace" \
            "getBoosterThresholds()[I" \
            "$SOURCE_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD" \
            "$TARGET_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replace" \
            "getBoosterThresholds()[I" \
            "$SOURCE_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD" \
            "$TARGET_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replace" \
            "getBoosterThresholds()[I" \
            "$SOURCE_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD" \
            "$TARGET_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD"
    else
        LOG_MISSING_PATCHES "SOURCE_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD" "TARGET_WLAN_CONFIG_CPU_CSTATE_DISABLE_THRESHOLD" || true
        LOG_MISSING_PATCHES "SOURCE_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD" "TARGET_WLAN_CONFIG_DATA_ACTIVITY_AFFINITY_BOOSTER_THRESHOLD" || true
        LOG_MISSING_PATCHES "SOURCE_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD" "TARGET_WLAN_CONFIG_L1SS_DISABLE_THRESHOLD"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_CONFIG_CUSTOM_BACKOFF
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_WLAN_CONFIG_CUSTOM_BACKOFF" != "$TARGET_WLAN_CONFIG_CUSTOM_BACKOFF" ]]; then
    target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/SemWifiCoexManager.smali")
    if [[ "$SOURCE_WLAN_CONFIG_CUSTOM_BACKOFF" != "none" ]] && [[ "$TARGET_WLAN_CONFIG_CUSTOM_BACKOFF" != "none" ]]; then
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "$SOURCE_WLAN_CONFIG_CUSTOM_BACKOFF" \
            "$TARGET_WLAN_CONFIG_CUSTOM_BACKOFF"
    elif [[ "$SOURCE_WLAN_CONFIG_CUSTOM_BACKOFF" == "none" ]] && [[ "$TARGET_WLAN_CONFIG_CUSTOM_BACKOFF" != "none" ]]; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/custom_backoff/semwifi-service.jar/0001-Allow-custom-CUSTOM_BACKOFF-value.patch"
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "CONFIG_CUSTOM_BACKOFF" \
            "$TARGET_WLAN_CONFIG_CUSTOM_BACKOFF"
    elif [[ "$SOURCE_WLAN_CONFIG_CUSTOM_BACKOFF" != "none" ]] && [[ "$TARGET_WLAN_CONFIG_CUSTOM_BACKOFF" == "none" ]]; then
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "$SOURCE_WLAN_CONFIG_CUSTOM_BACKOFF" \
            "CONFIG_CUSTOM_BACKOFF" > /dev/null
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/custom_backoff/semwifi-service.jar/0001-Remove-CUSTOM_BACKOFF-value.patch"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_80211AX
# ----------------------------------------------------------------------------------------
if $SOURCE_WLAN_SUPPORT_80211AX; then
    if $TARGET_WLAN_SUPPORT_80211AX; then
        if ! $SOURCE_WLAN_SUPPORT_80211AX_6GHZ; then
            if $TARGET_WLAN_SUPPORT_80211AX_6GHZ; then
                APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                    "$MODPATH/wifi/80211ax_6ghz/semwifi-service.jar/0001-Enable-80211AX_6GHZ-support.patch"
                APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                    "$MODPATH/wifi/80211ax_6ghz/SecSettings.apk/0001-Enable-80211AX_6GHZ-support.patch"
                APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
                    "$MODPATH/wifi/80211ax_6ghz/SystemUI.apk/0001-Enable-80211AX_6GHZ-support.patch"
            fi
        else
            if ! $TARGET_WLAN_SUPPORT_80211AX_6GHZ; then
                LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_80211AX_6GHZ" "TARGET_WLAN_SUPPORT_80211AX_6GHZ"
            fi
        fi
    else
        if $TARGET_WLAN_SUPPORT_80211AX_6GHZ; then
            ABORT "TARGET_WLAN_SUPPORT_80211AX is required by TARGET_WLAN_SUPPORT_80211AX_6GHZ"
        fi
        if ! $SOURCE_WLAN_SUPPORT_80211AX_6GHZ; then
            APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                "$MODPATH/wifi/80211ax/semwifi-service.jar/0001-Disable-80211AX-support.patch"
            APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                "$MODPATH/wifi/80211ax/SecSettings.apk/0001-Disable-80211AX-support.patch"
            APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
                "$MODPATH/wifi/80211ax/SystemUI.apk/0001-Disable-80211AX-support.patch"
        else
            LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_80211AX" "TARGET_WLAN_SUPPORT_80211AX" || true
            LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_80211AX_6GHZ" "TARGET_WLAN_SUPPORT_80211AX_6GHZ"
        fi
    fi
else
    if $SOURCE_WLAN_SUPPORT_80211AX_6GHZ; then
        ABORT "SOURCE_WLAN_SUPPORT_80211AX is required by SOURCE_WLAN_SUPPORT_80211AX_6GHZ"
    fi
    if $TARGET_WLAN_SUPPORT_80211AX; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_80211AX" "TARGET_WLAN_SUPPORT_80211AX"
    fi
    if $TARGET_WLAN_SUPPORT_80211AX_6GHZ; then
        ABORT "TARGET_WLAN_SUPPORT_80211AX is required by TARGET_WLAN_SUPPORT_80211AX_6GHZ"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_APE_SERVICE
# ----------------------------------------------------------------------------------------
if [[ "$SOURCE_WLAN_CONFIG_CONNECTION_PERSONALIZATION" != "$TARGET_WLAN_CONFIG_CONNECTION_PERSONALIZATION" ]] || \
        [[ "$SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH" != "$TARGET_WLAN_CONFIG_DYNAMIC_SWITCH" ]] || \
        [[ "$SOURCE_WLAN_SUPPORT_APE_SERVICE" != "$TARGET_WLAN_SUPPORT_APE_SERVICE" ]]; then
    if [[ "$SOURCE_WLAN_CONFIG_CONNECTION_PERSONALIZATION" == "1" ]] && $SOURCE_WLAN_SUPPORT_APE_SERVICE; then

        target_inj_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/SemWifiInjector.smali")

        if [[ "$SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH" != "0" ]]; then
            SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
                "$target_inj_path" "replace" \
                "<init>(Landroid/content/Context;)V" \
                "$SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH" \
                "0" > /dev/null
        fi
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/connection_personalization/semwifi-service.jar/0001-Allow-custom-CONNECTION_PERSONALIZATION-value.patch"
        if [[ "$SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH" != "0" ]]; then
            SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
                "$target_inj_path" "replace" \
                "<init>(Landroid/content/Context;)V" \
                "0" \
                "$SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH" > /dev/null
        fi
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_inj_path" "replace" \
            "<init>(Landroid/content/Context;)V" \
            "$SOURCE_WLAN_CONFIG_CONNECTION_PERSONALIZATION" \
            "$TARGET_WLAN_CONFIG_CONNECTION_PERSONALIZATION"

        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$MODPATH/wifi/connection_personalization/SecSettings.apk/0001-Allow-custom-CONNECTION_PERSONALIZATION-value.patch"

        target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes3/com/samsung/android/settings/wifi/develop/btm/BtmController.smali")
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$target_path" "replace" \
            "getAvailabilityStatus()I" \
            "$SOURCE_WLAN_CONFIG_CONNECTION_PERSONALIZATION" \
            "$TARGET_WLAN_CONFIG_CONNECTION_PERSONALIZATION"

        if [[ "$SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH" != "$TARGET_WLAN_CONFIG_DYNAMIC_SWITCH" ]]; then
            SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
                "$target_inj_path" "replace" \
                "<init>(Landroid/content/Context;)V" \
                "$SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH" \
                "$TARGET_WLAN_CONFIG_DYNAMIC_SWITCH"

            target_res_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/SemWifiResourceManager.smali")
            SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
                "$target_res_path" "replace" \
                "<init>(Landroid/content/Context;Lcom/samsung/android/server/wifi/halclient/SemWifiNative;Lcom/samsung/android/server/wifi/SemWifiInjector;)V" \
                "$SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH" \
                "$TARGET_WLAN_CONFIG_DYNAMIC_SWITCH"

            target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes2/com/android/settings/development/WifiSafePreferenceController.smali")
            SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                "$target_path" "replace" \
                "<init>(Landroid/content/Context;)V" \
                "$SOURCE_WLAN_CONFIG_DYNAMIC_SWITCH" \
                "$TARGET_WLAN_CONFIG_DYNAMIC_SWITCH"
        fi

        if ! $TARGET_WLAN_SUPPORT_APE_SERVICE; then
            APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                "$MODPATH/wifi/ape_service/semwifi-service.jar/0001-Disable-APE_SERVICE-support.patch"

            target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/SemQboxController\$1.smali")
            SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
                "$target_path" "remove"
            APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                "$MODPATH/wifi/ape_service/SecSettings.apk/0001-Disable-APE_SERVICE-support.patch"
        fi
    else
        LOG_MISSING_PATCHES "SOURCE_WLAN_CONFIG_CONNECTION_PERSONALIZATION" "TARGET_WLAN_CONFIG_CONNECTION_PERSONALIZATION" || true
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_APE_SERVICE" "TARGET_WLAN_SUPPORT_APE_SERVICE"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MBO
# ----------------------------------------------------------------------------------------
target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali")
if ! $SOURCE_WLAN_SUPPORT_MBO && $TARGET_WLAN_SUPPORT_MBO; then
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "$target_path" "return" \
        "isMBOSupported()Z" \
        "true"
elif $SOURCE_WLAN_SUPPORT_MBO && ! $TARGET_WLAN_SUPPORT_MBO; then
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "$target_path" "return" \
        "isMBOSupported()Z" \
        "false"
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY
# ----------------------------------------------------------------------------------------
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY; then
    if $TARGET_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/5g_basedon_country/semwifi-service.jar/0001-Enable-MOBILEAP_5G_BASEDON_COUNTRY-support.patch"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "SPF_5G_BASEDON_COUNTRY=false" \
            "SPF_5G_BASEDON_COUNTRY=true"
    fi
else
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY" "TARGET_WLAN_SUPPORT_MOBILEAP_5G_BASEDON_COUNTRY"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_6G
# ----------------------------------------------------------------------------------------
target_ap_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali")
target_facade_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali")

if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_6G && $TARGET_WLAN_SUPPORT_MOBILEAP_6G; then
    ADD_TO_WORK_DIR "b0qxxx" "product" "overlay/SoftapOverlay6GHz/SoftapOverlay6GHz.apk" 0 0 644 "u:object_r:system_file:s0"

    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "$target_ap_path" "replaceall" \
        "SPF_6G=false" \
        "SPF_6G=true"
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "$target_facade_path" "return" \
        "isSupportMobileAp6G()Z" \
        "true"
elif $SOURCE_WLAN_SUPPORT_MOBILEAP_6G && ! $TARGET_WLAN_SUPPORT_MOBILEAP_6G; then
    DELETE_FROM_WORK_DIR "product" "overlay/SoftapOverlay6GHz"

    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "$target_ap_path" "replaceall" \
        "SPF_6G=true" \
        "SPF_6G=false"
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "$target_facade_path" "return" \
        "isSupportMobileAp6G()Z" \
        "false"
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_DUALAP
# ----------------------------------------------------------------------------------------
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_DUALAP; then
    if $TARGET_WLAN_SUPPORT_MOBILEAP_DUALAP; then
        ADD_TO_WORK_DIR "dm1qxxx" "product" "overlay/SoftapOverlayDualAp/SoftapOverlayDualAp.apk" 0 0 644 "u:object_r:system_file:s0"

        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/dualap/semwifi-service.jar/0001-Enable-MOBILEAP_DUALAP-support.patch"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "SPF_DualAp=false" \
            "SPF_DualAp=true"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration\$6.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" "$target_path" "remove"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration\$12.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" "$target_path" "remove"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration\$16.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" "$target_path" "remove"

        if $TARGET_COMMON_SUPPORT_DYN_RESOLUTION_CONTROL; then
            APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                "$MODPATH/wifi/dualap_resolution/SecSettings.apk/0001-Enable-MOBILEAP_DUALAP-support.patch"
        else
            APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
                "$MODPATH/wifi/dualap/SecSettings.apk/0001-Enable-MOBILEAP_DUALAP-support.patch"
        fi

        target_path=$(find_smali_file "system/priv-app/SecSettings/SecSettings.apk" "smali_classes3/com/samsung/android/settings/wifi/mobileap/WifiApSmartSwitchBackupRestore\$5.smali")
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$target_path" "remove"
    fi
else
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_DUALAP; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_DUALAP" "TARGET_WLAN_SUPPORT_MOBILEAP_DUALAP"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_OWE
# ----------------------------------------------------------------------------------------
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_OWE; then
    if $TARGET_WLAN_SUPPORT_MOBILEAP_OWE; then
        ADD_TO_WORK_DIR "dm1qxxx" "product" "overlay/SoftapOverlayOWE/SoftapOverlayOWE.apk" 0 0 644 "u:object_r:system_file:s0"

        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/owe/semwifi-service.jar/0001-Enable-MOBILEAP_OWE-support.patch"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "SPF_OWE=false" \
            "SPF_OWE=true"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$MODPATH/wifi/owe/SecSettings.apk/0001-Enable-MOBILEAP_OWE-support.patch"
    fi
else
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_OWE; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_OWE" "TARGET_WLAN_SUPPORT_MOBILEAP_OWE"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE
# ----------------------------------------------------------------------------------------
if $SOURCE_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE; then
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/power_savemode/semwifi-service.jar/0001-Disable-MOBILEAP_POWER_SAVEMODE-support.patch"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "SPF_POWER_SAVEMODE=true" \
            "SPF_POWER_SAVEMODE=false"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemWifiApPowerSaveImpl\$\$ExternalSyntheticLambda0.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" "$target_path" "remove"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemWifiApPowerSaveImpl\$\$ExternalSyntheticLambda1.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" "$target_path" "remove"
    fi
else
    if $TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE" "TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC
# ----------------------------------------------------------------------------------------
if $SOURCE_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC; then
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC; then
        DELETE_FROM_WORK_DIR "system" "system/app/MhsAiService"
        DELETE_FROM_WORK_DIR "system" "system/etc/xgb_mhs_l1.model"

        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/prioritize_traffic/semwifi-service.jar/0001-Disable-MOBILEAP_PRIORITIZE_TRAFFIC-support.patch"

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "SPF_Prio_Traffic=true" \
            "SPF_Prio_Traffic=false"
        APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "$MODPATH/wifi/prioritize_traffic/SecSettings.apk/0001-Disable-MOBILEAP_PRIORITIZE_TRAFFIC-support.patch"
    fi
else
    if $TARGET_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC" "TARGET_WLAN_SUPPORT_MOBILEAP_PRIORITIZE_TRAFFIC"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SEC_SUPPORT_MOBILEAP_WIFI_CONCURRENCY
# ----------------------------------------------------------------------------------------
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY; then
    if $TARGET_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY; then
        if ! $TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE; then
            APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                "$MODPATH/wifi/power_savemode/semwifi-service.jar/0002-Enable-MOBILEAP_WIFI_CONCURRENCY-support.patch"
        else
            APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                "$MODPATH/wifi/wifisharing/semwifi-service.jar/0001-Enable-MOBILEAP_WIFI_CONCURRENCY-support.patch"
        fi

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "SPF_Concurrency=false" \
            "SPF_Concurrency=true"
    fi
else
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY" "TARGET_WLAN_SUPPORT_MOBILEAP_WIFI_CONCURRENCY"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE
# ----------------------------------------------------------------------------------------
if ! $SOURCE_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE; then
    if $TARGET_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE; then
        if ! $TARGET_WLAN_SUPPORT_MOBILEAP_POWER_SAVEMODE; then
            APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                "$MODPATH/wifi/power_savemode/semwifi-service.jar/0003-Enable-MOBILEAP_WIFISHARING_LITE-support.patch"
        else
            APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                "$MODPATH/wifi/wifisharing/semwifi-service.jar/0002-Enable-MOBILEAP_WIFISHARING_LITE-support.patch"
        fi

        target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/ap/SemSoftApConfiguration.smali")
        SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
            "$target_path" "replaceall" \
            "SPF_WS_Lite=false" \
            "SPF_WS_Lite=true"
    fi
else
    if ! $TARGET_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE" "TARGET_WLAN_SUPPORT_MOBILEAP_WIFISHARING_LITE"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_TWT_CONTROL & SEC_PRODUCT_FEATURE_WLAN_SUPPORT_LOWLATENCY
# ----------------------------------------------------------------------------------------
if $SOURCE_WLAN_SUPPORT_TWT_CONTROL && $SOURCE_WLAN_SUPPORT_LOWLATENCY; then
    if ! $TARGET_WLAN_SUPPORT_TWT_CONTROL; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/twt_control/semwifi-service.jar/0001-Disable-TWT_CONTROL-support.patch"

        if ! $TARGET_WLAN_SUPPORT_LOWLATENCY; then
            APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
                "$MODPATH/wifi/twt_control/semwifi-service.jar/0002-Disable-LOWLATENCY-support.patch"
        fi
    elif ! $TARGET_WLAN_SUPPORT_LOWLATENCY; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/lowlatency/semwifi-service.jar/0001-Disable-LOWLATENCY-support.patch"
    fi
else
    if ! $SOURCE_WLAN_SUPPORT_TWT_CONTROL && $TARGET_WLAN_SUPPORT_TWT_CONTROL; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_TWT_CONTROL" "TARGET_WLAN_SUPPORT_TWT_CONTROL"
    elif ! $SOURCE_WLAN_SUPPORT_LOWLATENCY && $TARGET_WLAN_SUPPORT_LOWLATENCY; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_LOWLATENCY" "TARGET_WLAN_SUPPORT_LOWLATENCY"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS
# ----------------------------------------------------------------------------------------
if $SOURCE_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS; then
    if ! $TARGET_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS; then
        APPLY_PATCH "system" "system/framework/semwifi-service.jar" \
            "$MODPATH/wifi/individual_apps/semwifi-service.jar/0001-Disable-SWITCH_FOR_INDIVIDUAL_APPS-support.patch"
    fi
else
    if $TARGET_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS; then
        LOG_MISSING_PATCHES "SOURCE_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS" "TARGET_WLAN_SUPPORT_SWITCH_FOR_INDIVIDUAL_APPS"
    fi
fi

# ----------------------------------------------------------------------------------------
# SEC_PRODUCT_FEATURE_WLAN_SUPPORT_WIFI_TO_CELLULAR
# ----------------------------------------------------------------------------------------
target_path=$(find_smali_file "system/framework/semwifi-service.jar" "smali/com/samsung/android/server/wifi/SemFrameworkFacade.smali")
if ! $SOURCE_WLAN_SUPPORT_WIFI_TO_CELLULAR && $TARGET_WLAN_SUPPORT_WIFI_TO_CELLULAR; then
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "$target_path" "return" \
        "isWifiToCellularSupported()Z" \
        "true"
elif $SOURCE_WLAN_SUPPORT_WIFI_TO_CELLULAR && ! $TARGET_WLAN_SUPPORT_WIFI_TO_CELLULAR; then
    SMALI_PATCH "system" "system/framework/semwifi-service.jar" \
        "$target_path" "return" \
        "isWifiToCellularSupported()Z" \
        "false"
fi

unset TARGET_FIRMWARE_PATH
unset -f GET_FINGERPRINT_SENSOR_TYPE LOG_MISSING_PATCHES find_smali_file
