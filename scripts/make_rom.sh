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
if $BUILD_ROM; then
    LOG_STEP_IN true "Generating Dynamic Partition tools for Tab S7"

    # 키친 툴 내부의 lpmake 도구 위치 정의 (UN1CA 기본 bin 폴더 내의 실행파일 확인 필요)
    LPMAKE_BIN="$SRC_DIR/scripts/bin/lpmake"
    [ ! -f "$LPMAKE_BIN" ] && LPMAKE_BIN="lpmake" # 시스템 패스에 잡혀있을 경우 대비

    # 1. super_empty.img 자동 빌드 (탭 S7 물리 규격 고정값 적용)
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

    # 2. 패키징 완료된 각 파티션 이미지의 순수 크기 측정 (바이트 단위)
    # UN1CA 작업 디렉토리 경로에 맞게 이미지 파일 존재 여부 체크 후 변수 할당
    SYSTEM_IMG="$WORK_DIR/system.img"
    VENDOR_IMG="$WORK_DIR/vendor.img"
    PRODUCT_IMG="$WORK_DIR/product.img"
    ODM_IMG="$WORK_DIR/odm.img"

    # 이미지 크기 읽어오기 (파일이 없으면 0으로 처리)
    SYSTEM_SIZE=[ -f "$SYSTEM_IMG" ] && stat -c%s "$SYSTEM_IMG" || echo 0
    VENDOR_SIZE=[ -f "$VENDOR_IMG" ] && stat -c%s "$VENDOR_IMG" || echo 0
    PRODUCT_SIZE=[ -f "$PRODUCT_IMG" ] && stat -c%s "$PRODUCT_IMG" || echo 0
    ODM_SIZE=[ -f "$ODM_IMG" ] && stat -c%s "$ODM_IMG" || echo 0

    # 안전 마진 버퍼 추가 (여유 공간 약 30MB 강제 할당하여 플래싱 여유 확보)
    BUFFER=31457280
    SYSTEM_SIZE=$((SYSTEM_SIZE + BUFFER))
    VENDOR_SIZE=$((VENDOR_SIZE + BUFFER))
    PRODUCT_SIZE=$((PRODUCT_SIZE + BUFFER))
    ODM_SIZE=$((ODM_SIZE + BUFFER))

    # 3. dynamic_partitions_op_list 파일 생성
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

    # 4. 최종 ZIP에 묶이도록 빌드 타겟 경로에 복사 처리
    # (UN1CA의 스크립트 특성상 create_target_files_zip.sh 내부나 
    # 혹은 플래시 가능한 zip 루트 경로(예: META-INF가 있는 곳)에 삽입되도록 연동해 줘야 함)
    # 일단 생성 완료 로그 출력
    LOGI "super_empty.img and dynamic_partitions_op_list generated successfully."
    LOG_STEP_OUT
fi
### 🛠️ DYNAMIC PARTITION AUTO SCRIPT END ###

if $BUILD_TARGET_FILES || $BUILD_FLASHABLE_ZIP; then
    ZIP_FILE_NAME="${TARGET_CODENAME}_"
    if [ "$(GET_PROP "system" "ro.unica.version")" ]; then
        ZIP_FILE_NAME+="$(GET_PROP "system" "ro.unica.version")"
    else
        ZIP_FILE_NAME+="$ROM_VERSION"
    fi
    ZIP_FILE_NAME+="-target_files.zip"

    if [ ! -f "$OUT_DIR/$ZIP_FILE_NAME" ]; then
        LOG_STEP_IN true "Creating target-files zip"
        "$SRC_DIR/scripts/internal/create_target_files_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
        LOG_STEP_OUT
    else
        LOGW "File already exists: ${OUT_DIR//$SRC_DIR\//}/$ZIP_FILE_NAME"
    fi

    if $BUILD_FLASHABLE_ZIP; then
        LOG_STEP_IN true "Creating flashable zip"
        "$SRC_DIR/scripts/build_flashable_zip.sh" "$OUT_DIR/$ZIP_FILE_NAME" || exit 1
        LOG_STEP_OUT
    fi
fi

exit 0
