# Nuke WSM (파일이 없어도 빌드가 터지거나 경고를 뱉지 않도록 에러 무시 처리)
DELETE_FROM_WORK_DIR "system" "system/etc/public.libraries-wsm.samsung.txt" || true
DELETE_FROM_WORK_DIR "system" "system/lib/libhal.wsm.samsung.so" || true
DELETE_FROM_WORK_DIR "system" "system/lib/vendor.samsung.hardware.security.wsm.service-V1-ndk.so" || true
DELETE_FROM_WORK_DIR "system" "system/lib64/libhal.wsm.samsung.so" || true
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.wsm.service-V1-ndk.so" || true

# Add KnoxPatchHooks
APPLY_PATCH "system" "system/framework/framework.jar" \
    "$MODPATH/framework.jar/0001-Introduce-KnoxPatchHooks.patch"
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali/android/app/Instrumentation.smali" "replace" \
    'newApplication(Ljava/lang/Class;Landroid/content/Context;)Landroid/app/Application;' \
    'return-object p0' \
    '    invoke-static {p1}, Lio/mesalabs/unica/KnoxPatchHooks;->init(Landroid/content/Context;)V\n\n    return-object p0' \
    > /dev/null
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali/android/app/Instrumentation.smali" "replace" \
    'newApplication(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Context;)Landroid/app/Application;' \
    'return-object p0' \
    '    invoke-static {p3}, Lio/mesalabs/unica/KnoxPatchHooks;->init(Landroid/content/Context;)V\n\n    return-object p0' \
    > /dev/null
APPLY_PATCH "system" "system/framework/knoxsdk.jar" \
    "$MODPATH/knoxsdk.jar/0001-Introduce-KnoxPatchHooks.patch"

# Bypass ICD verification (Git 패치 실패 시 Smali로 직접 조지는 Fallback 로직 적용)
SMALI_PATCH "system" "system/framework/samsungkeystoreutils.jar" \
    "smali/com/samsung/android/security/keystore/AttestParameterSpec.smali" "return" \
    'isVerifiableIntegrity()Z' 'true' || true

if ! APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/services.jar/0001-Bypass-ICD-verification.patch"; then
    
    LOG "- Git patch failed for ICD verification. Applying Smali fallback logic..."
    
    # 패치 파일 내부에서 건드리려던 핵심 타겟들을 직접 Smali 단에서 후킹 및 리턴값 변조
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali_classes2/com/samsung/android/security/keystore/AttestParameterSpec.smali" "return" \
        "isVerifiableIntegrity()Z" "true" || true

    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/knox/dar/DarManagerService.smali" "return" \
        "isIcdEnabled()Z" "false" || true
fi

# Disable SAK in DarManagerService
SMALI_PATCH "system" "system/framework/services.jar" \
    "smali/com/android/server/knox/dar/DarManagerService.smali" "return" \
    'checkDeviceIntegrity([Ljava/security/cert/Certificate;)Z' 'true'

# Disable DRK in DarManagerService
SMALI_PATCH "system" "system/framework/services.jar" \
    "smali/com/android/server/knox/dar/DarManagerService.smali" "return" \
    'isDeviceRootKeyInstalled()Z' 'true'

# Disable root checks in StorageManagerService
SMALI_PATCH "system" "system/framework/services.jar" \
    "smali/com/android/server/StorageManagerService.smali" "return" \
    'isRootedDevice()Z' 'false'

# Spoof ROT/IntegrityStatus in Knox Matrix
if [ -f "$WORK_DIR/system/system/priv-app/KmxService/KmxService.apk" ]; then
    LOG "- Downloading latest Knox Matrix app"
    DOWNLOAD_FILE "$(GET_GALAXY_STORE_DOWNLOAD_URL "com.samsung.android.kmxservice")" \
        "$WORK_DIR/system/system/priv-app/KmxService/KmxService.apk"
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/common/util/RootOfTrust.smali" "return" \
        'getVerifiedBootState()I' '0'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/common/util/RootOfTrust.smali" "return" \
        'isDeviceLocked()Z' 'true'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/fabrickeystore/keystore/cert/RootOfTrust.smali" "return" \
        'getVerifiedBootState()I' '0'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/fabrickeystore/keystore/cert/RootOfTrust.smali" "return" \
        'isDeviceLocked()Z' 'true'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/sdk/trustchain/util/RootOfTrust.smali" "return" \
        'getVerifiedBootState()I' '0'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/sdk/trustchain/util/RootOfTrust.smali" "return" \
        'isDeviceLocked()Z' 'true'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/common/util/IntegrityStatus.smali" "return" \
        'getStatus()I' '0'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/common/util/IntegrityStatus.smali" "return" \
        'isNormal()Z' 'true'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/fabrickeystore/keystore/cert/IntegrityStatus.smali" "return" \
        'isNormal()Z' 'true'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/sdk/trustchain/util/IntegrityStatus.smali" "return" \
        'getStatus()I' '0'
    SMALI_PATCH "system" "system/priv-app/KmxService/KmxService.apk" \
        "smali/com/samsung/android/kmxservice/sdk/trustchain/util/IntegrityStatus.smali" "return" \
        'isNormal()Z' 'true'
fi
