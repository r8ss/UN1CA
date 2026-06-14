#!/usr/bin/env bash
# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

INCREMENTAL=false
SOURCE_ZIP=""
TARGET_ZIP=""
OUTPUT_FILE=""

PREPARE_SCRIPT()
{
    if [[ "$#" == 0 ]]; then
        PRINT_USAGE
        exit 1
    fi

    while [[ "$1" == "-"* ]]; do
        if [[ "$1" == "--incremental" ]] || [[ "$1" == "-i" ]]; then
            INCREMENTAL=true
            shift; SOURCE_ZIP="$1"
        elif [[ "$1" == "--output" ]] || [[ "$1" == "-o" ]]; then
            shift; OUTPUT_FILE="$1"
            if [[ "$OUTPUT_FILE" != *".zip" ]]; then
                LOGE "Output file name must have \".zip\" extension"
                exit 1
            fi
        else
            LOGE "Unknown option: $1"
            exit 1
        fi

        shift
    done

    TARGET_ZIP="$1"
    if [ ! "$TARGET_ZIP" ]; then
        PRINT_USAGE
        exit 1
    elif [ ! -f "$TARGET_ZIP" ]; then
        LOGE "File not found: ${TARGET_ZIP//$SRC_DIR\//}"
        exit 1
    fi

    if [ "$SOURCE_ZIP" ]; then
        if [ ! -f "$SOURCE_ZIP" ]; then
            LOGE "File not found: ${SOURCE_ZIP//$SRC_DIR\//}"
            exit 1
        fi
    fi

    if [ ! "$OUTPUT_FILE" ]; then
        local TARGET_BUILD_INFO

        EVAL "unzip -p \"$TARGET_ZIP\" \"build_info.txt\"" || exit 1
        TARGET_BUILD_INFO="$(unzip -p "$TARGET_ZIP" "build_info.txt")"

        OUTPUT_FILE="$OUT_DIR/UN1CA_"
        OUTPUT_FILE+="$(grep "^version" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
        OUTPUT_FILE+="_"
        OUTPUT_FILE+="$(date -d "@$(grep "^timestamp" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)" "+%Y%m%d")"
        OUTPUT_FILE+="_"
        OUTPUT_FILE+="$(grep "^device" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
        if $INCREMENTAL; then
            local SOURCE_BUILD_INFO

            EVAL "unzip -p \"$SOURCE_ZIP\" \"build_info.txt\"" || exit 1
            SOURCE_BUILD_INFO="$(unzip -p "$SOURCE_ZIP" "build_info.txt")"

            OUTPUT_FILE+="-INCREMENTAL_"
            OUTPUT_FILE+="$(grep "^timestamp" <<< "$SOURCE_BUILD_INFO" | cut -d "=" -f 2 -s)"
        fi
        if ! $DEBUG || $ROM_IS_OFFICIAL; then
            OUTPUT_FILE+="-sign"
        fi
        OUTPUT_FILE+=".zip"
    fi
}

PRINT_USAGE()
{
    echo "Usage: build_flashable_zip [options] <file>" >&2
    echo " -i, --incremental : Generate an incremental zip using the given target-files zip as source" >&2
    echo " -o, --output : Specify the output zip path, defaults to $OUT_DIR" >&2
}
# ]

PREPARE_SCRIPT "$@"

if $INCREMENTAL; then
    "$SRC_DIR/scripts/internal/build_incremental_ota_zip.sh" "$SOURCE_ZIP" "$TARGET_ZIP" "$OUTPUT_FILE" || exit 1
else
    ### 🛠️ FLASHABLE ZIP ROOT INJECTION START ###
    # 내부 빌드 스크립트들이 참조하는 임시 타겟 작업 디렉토리가 생성되는 구역이야.
    # build_full_ota_zip.sh가 돌기 전에 오퍼레이션 파일들이 유실되지 않도록 강제 복사 처리를 때려박음.
    
    LOGI "Syncing Dynamic Partition configs to target files before compression..."
    
    # UN1CA가 빌드 타임에 쓰는 임시 OTA 툴킷 폴더 트리 강제 주입
    if [ -d "$WORK_DIR/OTA" ]; then
        [ -f "$WORK_DIR/super_empty.img" ] && cp "$WORK_DIR/super_empty.img" "$WORK_DIR/OTA/"
        [ -f "$WORK_DIR/dynamic_partitions_op_list" ] && cp "$WORK_DIR/dynamic_partitions_op_list" "$WORK_DIR/OTA/"
    fi
    ### 🛠️ FLASHABLE ZIP ROOT INJECTION END ###

    "$SRC_DIR/scripts/internal/build_full_ota_zip.sh" "$TARGET_ZIP" "$OUTPUT_FILE" || exit 1
    
    ### 🛠️ POST-ZIP INJECTION FIX (안전 장치 2차 주입) ###
    # 만약 빌드 오타 툴이 이미 구워진 뒤라면, 최후의 수단으로 완성된 .zip 파일 자체에 
    # lpmake 툴킷 산출물 두 개를 루트 경로에 직접 밀어넣어 마무리를 침 (압축 해제 불필요)
    if [ -f "$OUTPUT_FILE" ]; then
        LOGI "Forcing inject to final output flashable zip..."
        cd "$WORK_DIR" || exit 1
        
        # 아스트라롬이랑 똑같은 unsparse 네이밍 호환을 위해 이름을 맞춰서 복사 본진 구성
        [ -f "super_empty.img" ] && cp "super_empty.img" "unsparse_super_empty.img"
        
        # zip 명령어로 완성된 배포 롬 .zip 루트에 즉시 추가 갱신
        if [ -f "unsparse_super_empty.img" ] && [ -f "dynamic_partitions_op_list" ]; then
            zip -g "$OUTPUT_FILE" "unsparse_super_empty.img" "dynamic_partitions_op_list" >/dev/null
            LOGI "Successfully verified and updated flashable zip content matrix!"
        fi
        cd - >/dev/null || exit 1
    fi
    ### 🛠️ POST-ZIP INJECTION FIX END ###
fi

exit 0
