if [ ! "$(GET_PROP "system" "ro.unica.version")" ]; then
    SET_PROP "system" "ro.unica.version" "$ROM_VERSION"
fi

SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali/android/app/Instrumentation.smali" "replace" \
    'newApplication(Ljava/lang/Class;Landroid/content/Context;)Landroid/app/Application;' \
    'invoke-virtual {p0, p1}, Landroid/app/Application;->attach(Landroid/content/Context;)V' \
    '    invoke-virtual {p0, p1}, Landroid/app/Application;->attach(Landroid/content/Context;)V\n\n    invoke-static {p1}, Lio/mesalabs/unica/SamsungPropsHooks;->init(Landroid/content/Context;)V' \
    > /dev/null
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali/android/app/Instrumentation.smali" "replace" \
    'newApplication(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Context;)Landroid/app/Application;' \
    'invoke-virtual {p0, p3}, Landroid/app/Application;->attach(Landroid/content/Context;)V' \
    '    invoke-virtual {p0, p3}, Landroid/app/Application;->attach(Landroid/content/Context;)V\n\n    invoke-static {p3}, Lio/mesalabs/unica/SamsungPropsHooks;->init(Landroid/content/Context;)V' \
    > /dev/null

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

# ====================================================================
# [UN1CA 추가] AndroidManifest.xml에 설정 액티비티 인젝션
# ====================================================================
MANIFEST_FILE="$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/AndroidManifest.xml"

if [ -f "$MANIFEST_FILE" ]; then
    LOG "- Injecting UN1CA Settings Activities into AndroidManifest.xml"
    
    cat << 'EOF' > /tmp/unica_activities.xml
        <activity android:configChanges="keyboardHidden|orientation|screenSize" android:exported="true" android:label="@string/unica_settings_title" android:name="com.android.settings.Settings$UnicaSettingsActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
            <meta-data android:name="com.android.settings.FRAGMENT_CLASS" android:value="io.mesalabs.unica.settings.UnicaSettingsFragment"/>
            <meta-data android:name="com.android.settings.HIGHLIGHT_MENU_KEY" android:value="@string/menu_key_unica_top_settings"/>
        </activity>
        <activity android:configChanges="keyboardHidden|orientation|screenSize" android:exported="true" android:label="@string/unica_extra_settings_title" android:name="com.android.settings.Settings$UnicaExtraSettingsActivity" android:parentActivityName="com.android.settings.Settings$UnicaSettingsActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
            <meta-data android:name="com.android.settings.FRAGMENT_CLASS" android:value="io.mesalabs.unica.settings.extra.ExtraSettingsFragment"/>
            <meta-data android:name="com.android.settings.HIGHLIGHT_MENU_KEY" android:value="@string/menu_key_unica_top_settings"/>
        </activity>
        <activity android:configChanges="keyboardHidden|orientation|screenSize" android:exported="true" android:label="@string/unica_hma_title" android:name="com.android.settings.Settings$UnicaHMASettingsActivity" android:parentActivityName="com.android.settings.Settings$UnicaSpoofSettingsActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
            <meta-data android:name="com.android.settings.FRAGMENT_CLASS" android:value="io.mesalabs.unica.settings.hma.HideMyApplistFragment"/>
            <meta-data android:name="com.android.settings.HIGHLIGHT_MENU_KEY" android:value="@string/menu_key_unica_top_settings"/>
        </activity>
        <activity android:configChanges="keyboardHidden|orientation|screenSize" android:exported="true" android:label="@string/unica_hide_dev_title" android:name="com.android.settings.Settings$UnicaHideDevSettingsActivity" android:parentActivityName="com.android.settings.Settings$UnicaSpoofSettingsActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
            <meta-data android:name="com.android.settings.FRAGMENT_CLASS" android:value="io.mesalabs.unica.settings.spoof.HideDeveloperStatusFragment"/>
            <meta-data android:name="com.android.settings.HIGHLIGHT_MENU_KEY" android:value="@string/menu_key_unica_top_settings"/>
        </activity>
        <activity android:configChanges="keyboardHidden|orientation|screenSize" android:exported="true" android:label="@string/unica_spoof_settings_title" android:name="com.android.settings.Settings$UnicaSpoofSettingsActivity" android:parentActivityName="com.android.settings.Settings$UnicaSettingsActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
            <meta-data android:name="com.android.settings.FRAGMENT_CLASS" android:value="io.mesalabs.unica.settings.spoof.SpoofSettingsFragment"/>
            <meta-data android:name="com.android.settings.HIGHLIGHT_MENU_KEY" android:value="@string/menu_key_unica_top_settings"/>
        </activity>
        <activity android:configChanges="keyboardHidden|orientation|screenSize" android:exported="true" android:label="@string/unica_ui_settings_title" android:name="com.android.settings.Settings$UnicaUISettingsActivity" android:parentActivityName="com.android.settings.Settings$UnicaSettingsActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
            <meta-data android:name="com.android.settings.FRAGMENT_CLASS" android:value="io.mesalabs.unica.settings.ui.UISettingsFragment"/>
            <meta-data android:name="com.android.settings.HIGHLIGHT_MENU_KEY" android:value="@string/menu_key_unica_top_settings"/>
        </activity>
        EOF

    sed -i '/<\/application>/r /tmp/unica_activities.xml' "$MANIFEST_FILE"
    rm -f /tmp/unica_activities.xml
else
    LOG "! Warning: Manifest file not found at $MANIFEST_FILE"
fi
# ====================================================================

# ====================================================================
# [UN1CA 추가] 디스플레이 관련 Git 패치 터짐 방지 가드 및 Smali 우회
# ====================================================================
# 만약 디스플레이 .patch 파일명이 다르면 아래 경로의 파일명만 본인 환경에 맞게 바꾸면 돼.
if ! APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$MODPATH/secsettings/0001-SecSettings-Display-Fix.patch" 2>/dev/null; then
    
    LOG "- Git patch failed for Display Settings. Applying Smali bypass logic..."

    # 1. 터지던 빅스비 액션 파일 컴파일 정상화 (결과 무시 또는 null 처리)
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "smali_classes4/com/samsung/android/settings/bixby/target/DisplayColorResetAction.smali" "return" \
        "doSetAction()Landroid/os/Bundle;" "null" || true

    # 2. 선명도/화면 모드 변경 팝업 에러 우회 (onClick 메소드 강제 탈출 처리)
    # 셸 변수 깨짐 방지를 위해 $3 앞에 백슬래시(\) 장착 완료
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "smali_classes4/com/samsung/android/settings/display/NewModePreview\$3.smali" "return" \
        "onClick(Landroid/content/DialogInterface;I)V" "void" || true
fi
# ====================================================================

# Disable stock OTA references
if [ ! -f "$WORK_DIR/system/system/priv-app/ChoiDujour/ChoiDujour.apk" ]; then
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "smali_classes3/com/samsung/android/settings/softwareupdate/SoftwareUpdateUtils.smali" "return" \
        'isOTAUpgradeAllowed(Landroid/content/Context;)Z' \
        'false'
fi

# Always show One UI minor version
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/settings/deviceinfo/softwareinfo/OneUIVersionPreferenceController.smali" "replace" \
    'isDeviceWithMicroVersion()Z' \
    'move-result p0' \
    'const/4 p0, 0x1'

# Show real device model number
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali_classes4/com/samsung/android/settings/deviceinfo/aboutphone/ModelNameGetter.smali" "replace" \
    'getModelName()Ljava/lang/String;' \
    'ro.product.model' \
    'ro.boot.em.model'

LOG_STEP_IN "- Adding UN1CA Settings"

# Dynamically patch SecSettings
while IFS= read -r f; do
    f="${f//$MODPATH\/SecSettings.apk\//}"

    if [ ! -f "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f" ] || \
            [[ "$f" != *".xml" ]]; then
        LOG "- Adding \"$f\" to /system/system/priv-app/SecSettings.apk"
        EVAL "mkdir -p \"$(dirname "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f")\""
        EVAL "cp -a \"$MODPATH/SecSettings.apk/${f//\$/\\$}\" \"$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/${f//\$/\\$}\""
    else
        LOG "- Patching \"$f\" in /system/system/priv-app/SecSettings.apk"
        if [[ "$f" == *"res/values"* ]]; then
            PATCH_INST="/<\/resources>/i"
            CONTENT="$(sed -e "/?xml/d" -e "/resources>/d" "$MODPATH/SecSettings.apk/$f")"
        else
            PATCH_INST="$(head -n 1 "$MODPATH/SecSettings.apk/$f")"
            CONTENT="$(tail -n +2 "$MODPATH/SecSettings.apk/$f")"
        fi
        CONTENT="$(sed -e "s/\"/\\\\\"/g" -e "s/\\$/\\\\$/g" -e "s/ /\\\ /g" -e "s/\\\\n/\\\\\\\\\n/g" <<< "$CONTENT")"
        CONTENT="$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' <<< "$CONTENT")"
        EVAL "sed -i \"$PATCH_INST $CONTENT\" \"$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f\""
    fi
done < <(find "$MODPATH/SecSettings.apk" -type f)

# Add UN1CA Settings SearchIndexDataProvider(s)
LOG "- Patching \"smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali\" in /system/system/priv-app/SecSettings.apk"
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    const-class v1, Lio/mesalabs/unica/settings/UnicaSettingsFragment;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    sget-object v2, Lio/mesalabs/unica/settings/UnicaSettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    invoke-virtual {p0, v0}, Lcom/android/settingslib/search/SearchIndexableResourcesBase;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    const-class v1, Lio/mesalabs/unica/settings/extra/ExtraSettingsFragment;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    sget-object v2, Lio/mesalabs/unica/settings/extra/ExtraSettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    invoke-virtual {p0, v0}, Lcom/android/settingslib/search/SearchIndexableResourcesBase;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    const-class v1, Lio/mesalabs/unica/settings/spoof/SpoofSettingsFragment;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    sget-object v2, Lio/mesalabs/unica/settings/spoof/SpoofSettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    invoke-virtual {p0, v0}, Lcom/android/settingslib/search/SearchIndexableResourcesBase;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    const-class v1, Lio/mesalabs/unica/settings/ui/UISettingsFragment;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    sget-object v2, Lio/mesalabs/unica/settings/ui/UISettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V\n\n    return-void' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "smali/com/android/settingslib/search/SearchIndexableResourcesBase.smali" "replace" \
    '<init>()V' \
    'return-void' \
    '    invoke-virtual {p0, v0}, Lcom/android/settingslib/search/SearchIndexableResourcesBase;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V\n\n    return-void' \
    > /dev/null

DECODE_APK "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
LOG "- Patching \"smali_classes2/com/samsung/android/settings/intelligence/search/categorizing/TopLevelKeysCollector.smali\" in /system/system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "smali_classes2/com/samsung/android/settings/intelligence/search/categorizing/TopLevelKeysCollector.smali" "replace" \
    '<init>(Landroid/content/Context;)V' \
    '.locals 36' \
    '.locals 37' \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "smali_classes2/com/samsung/android/settings/intelligence/search/categorizing/TopLevelKeysCollector.smali" "replace" \
    '<init>(Landroid/content/Context;)V' \
    'filled-new-array/range {v1 .. v35}, [Ljava/lang/String;' \
    '    const-string v36, "top_level_unica"\n\n    filled-new-array/range {v1 .. v36}, [Ljava/lang/String;' \
    > /dev/null

# Show Vulkan renderer toggle if required
if [[ "$(GET_PROP "ro.hwui.use_vulkan")" != "true" ]]; then
    SET_PROP "system" "persist.sys.unica.vulkan" "false"
fi

unset PATCH_INST CONTENT

LOG_STEP_OUT
