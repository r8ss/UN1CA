#!/usr/bin/env bash
# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

FORCE=false
BUILD_ROM=false
BUILD_TARGET_FILES=true
BUILD_FLASHABLE_ZIP=true

START_TIME="$(date +%s)"

SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

GET_WORK_DIR_HASH()
{
    find "$SRC_DIR/unica" "$SRC_DIR/target/$TARGET_CODENAME" -type f -print0 | \
        sort -z | xargs -0 sha1sum | sha1sum | cut -d " " -f 1
}

PREPARE_SCRIPT()
{
    while [ "$#" != 0 ]; do
        if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
            FORCE=true
        elif [[ "$1" == "--no-target-files" ]] || [[ "$1" == "-x" ]]; then
            BUILD_TARGET_FILES=false
            BUILD_FLASHABLE_ZIP=false
        elif [[ "$1" == "--build-rom-zip" ]] || [[ "$1" == "-z" ]]; then
            BUILD_TARGET_FILES=true
            BUILD_FLASHABLE_ZIP=true
        else
            if [[ "$1" == "-"* ]]; then
                LOGE "Unknown option: $1"
            fi
            PRINT_USAGE
            exit 1
        fi

        shift
    done
}

PRINT_BUILD_OUTCOME()
{
    local EXIT_CODE="$?"
    local END_TIME
    local ESTIMATED

    END_TIME="$(date +%s)"
    ESTIMATED="$((END_TIME - START_TIME))"

    if [ "$EXIT_CODE" != "0" ]; then
        echo -n -e '\n\033[1;31m'"Build failed "
    else
        echo -n -e '\n\033[1;32m'"Build completed "
    fi
    echo -e "in $((ESTIMATED / 3600))hrs $(((ESTIMATED / 60) % 60))min $((ESTIMATED % 60))sec."'\033[0m\n'
}

PRINT_USAGE()
{
    echo "Usage: make_rom [options]" >&2
    echo " -f, --force : Force ROM build" >&2
    echo " -x, --no-target-files : Do not build target-files zip" >&2
    echo " -z, --build-rom-zip : Build flashable zip" >&2
}

PREPARE_SCRIPT "$@"

if $FORCE; then
    BUILD_ROM=true
else
    if [ -f "$WORK_DIR/.completed" ]; then
        if [[ "$(cat "$WORK_DIR/.completed")" == "$(GET_WORK_DIR_HASH)" ]]; then
            LOGW "No changes have been detected in the build environment"
            BUILD_ROM=false
        else
            LOGW "Changes detected in the build environment"
            BUILD_ROM=true
        fi
    else
        BUILD_ROM=true
    fi
fi

trap 'PRINT_BUILD_OUTCOME' EXIT
trap 'echo' INT

if $BUILD_ROM; then
    [ -d "$APKTOOL_DIR" ] && rm -rf "$APKTOOL_DIR"
    [ -f "$WORK_DIR/.completed" ] && rm -f "$WORK_DIR/.completed"

    if [ ! -f "$FW_DIR/$SOURCE_FIRMWARE_PATH/.extracted" ] || [ ! -f "$FW_DIR/$TARGET_FIRMWARE_PATH/.extracted" ]; then
        if [ ! -f "$ODIN_DIR/$SOURCE_FIRMWARE_PATH/.downloaded" ] || [ ! -f "$ODIN_DIR/$TARGET_FIRMWARE_PATH/.downloaded" ]; then
            LOG_STEP_IN true "Downloading required firmwares"
            "$SRC_DIR/scripts/download_fw.sh" || exit 1
            LOG_STEP_OUT
        fi
        LOG_STEP_IN true "Extracting required firmwares"
        "$SRC_DIR/scripts/extract_fw.sh" || exit 1
        LOG_STEP_OUT
    fi

    LOG_STEP_IN true "Creating work dir"
    "$SRC_DIR/scripts/internal/create_work_dir.sh" || exit 1
    LOG_STEP_OUT

    if [ -d "$SRC_DIR/platform/$TARGET_PLATFORM/patches" ]; then
        LOG_STEP_IN true "Applying platform patches"
        "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/platform/$TARGET_PLATFORM/patches" || exit 1
        LOG_STEP_OUT
    fi
    if [ -d "$SRC_DIR/target/$TARGET_CODENAME/patches" ]; then
        LOG_STEP_IN true "Applying device patches"
        "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/target/$TARGET_CODENAME/patches" || exit 1
        LOG_STEP_OUT
    fi
    if [ -d "$SRC_DIR/unica/patches" ]; then
        LOG_STEP_IN true "Applying ROM patches"
        "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/patches" || exit 1
        LOG_STEP_OUT
    fi

    if [ -d "$SRC_DIR/unica/mods" ]; then
        LOG_STEP_IN true "Applying ROM mods"
        "$SRC_DIR/scripts/internal/apply_modules.sh" "$SRC_DIR/unica/mods" || exit 1
        LOG_STEP_OUT
    fi

    if [ -d "$APKTOOL_DIR" ]; then
        LOG_STEP_IN true "Building APKs/JARs"

        while IFS= read -r f; do
            f="${f/$APKTOOL_DIR\//}"
            PARTITION="$(cut -d "/" -f 1 -s <<< "$f")"
            if [[ "$PARTITION" == "system" ]]; then
                "$SRC_DIR/scripts/apktool.sh" b "system" "$f" &
            else
                "$SRC_DIR/scripts/apktool.sh" b "$PARTITION" "$(cut -d "/" -f 2- -s <<< "$f")" &
            fi
        done < <(find "$APKTOOL_DIR" -type d \( -name "*.apk" -o -name "*.jar" \))

        # shellcheck disable=SC2046
        wait $(jobs -p) || exit 1

        LOG_STEP_OUT
    fi

    echo -n "$(GET_WORK_DIR_HASH)" > "$WORK_DIR/.completed"
fi

### 🛠️ DYNAMIC PARTITION AUTO SCRIPT START ###
LOG_STEP_IN true "Generating Dynamic Partition tools for Tab S7"

# 키친 툴 내부의 lpmake 도구 위치 정의
LPMAKE_BIN="$SRC_DIR/scripts/bin/lpmake"
[ ! -f "$LPMAKE_BIN" ] && LPMAKE_BIN="lpmake"

# 1. super_empty.img 자동 빌드
"$LPMAKE_BIN" \
    --metadata-size 65536 \
    --metadata-slots 3 \
    --device super:10171187200 \
    --group qti_dynamic_partitions:10171187200 \
    --partition system:readonly:0:qti_dynamic_partitions \
    --partition vendor:readonly:0:qti_dynamic_partitions \
    --partition product:readonly:0:qti_dynamic_partitions \
    --partition odm:readonly:0:qti_dynamic_partitions \
    --output "$WORK_DIR/super_empty.img" || exit 1

# 2. 각 파티션 이미지 크기 강제 스캔 및 디버깅 루틴
# UN1CA 키친 버전에 따라 파일이 주입되는 멀티 경로 후보군 싹 다 지정
SYSTEM_SIZE=0; VENDOR_SIZE=0; PRODUCT_SIZE=0; ODM_SIZE=0

get_img_size() {
    local img_name="$1"
    # 1순위: WORK_DIR 루트, 2순위: WORK_DIR/OTA, 3순위: OUT_DIR 등 매핑 검사
    if [ -f "$WORK_DIR/$img_name" ]; then
        stat -c%s "$WORK_DIR/$img_name"
    elif [ -f "$WORK_DIR/OTA/$img_name" ]; then
        stat -c%s "$WORK_DIR/OTA/$img_name"
    elif [ -f "$SRC_DIR/target/$TARGET_CODENAME/$img_name" ]; then
        stat -c%s "$SRC_DIR/target/$TARGET_CODENAME/$img_name"
    else
        echo 0
    fi
}

SYSTEM_SIZE=$(get_img_size "system.img")
VENDOR_SIZE=$(get_img_size "vendor.img")
PRODUCT_SIZE=$(get_img_size "product.img")
ODM_SIZE=$(get_img_size "odm.img")

# [⚠️ 터미널 디버깅용 안내 문자 출력] 용량이 0으로 잡히는지 검사하기 위함
LOGI "--- Extracted Image Sizes (Raw Bytes) ---"
LOGI "System: $SYSTEM_SIZE | Vendor: $VENDOR_SIZE | Product: $PRODUCT_SIZE | ODM: $ODM_SIZE"

# 안전 마진 버퍼 추가 (30MB)
BUFFER=31457280
SYSTEM_SIZE=$((SYSTEM_SIZE + BUFFER))
VENDOR_SIZE=$((VENDOR_SIZE + BUFFER))
PRODUCT_SIZE=$((PRODUCT_SIZE + BUFFER))
ODM_SIZE=$((ODM_SIZE + BUFFER))

# 3. dynamic_partitions_op_list 파일 생성 및 초기화
OP_LIST="$WORK_DIR/dynamic_partitions_op_list"
echo "remove_all_groups" > "$OP_LIST"
echo "add_group qti_dynamic_partitions 10171187200" >> "$OP_LIST"
echo "add system qti_dynamic_partitions" >> "$OP_LIST"
echo "add vendor qti_dynamic_partitions" >> "$OP_LIST"
echo "add product qti_dynamic_partitions" >> "$OP_LIST"
echo "add odm qti_dynamic_partitions" >> "$OP_LIST"
echo "resize system $SYSTEM_SIZE" >> "$OP_LIST"
echo "resize vendor $VENDOR_SIZE" >> "$OP_LIST"
echo "resize product $PRODUCT_SIZE" >> "$OP_LIST"
echo "resize odm $ODM_SIZE" >> "$OP_LIST"

# 4. ZIP 패키징 툴 내부로 산출물 전달 링크
if [ -d "$WORK_DIR/OTA" ]; then
    cp "$WORK_DIR/super_empty.img" "$WORK_DIR/OTA/"
    cp "$WORK_DIR/dynamic_partitions_op_list" "$WORK_DIR/OTA/"
fi

LOGI "super_empty.img and dynamic_partitions_op_list generated successfully."
LOG_STEP_OUT
### 🛠️ DYNAMIC PARTITION AUTO SCRIPT END ###
