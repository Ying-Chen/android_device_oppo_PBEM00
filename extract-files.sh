#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=PBEM00
VENDOR=oppo

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
	case "${1}" in
		# Patch libs to load versioned libprotobuf from SDK 29, as SDK 32 removed some symbols
        vendor/lib64/libwvhidl.so)
        "${PATCHELF}" --replace-needed "libprotobuf-cpp-lite.so" "libprotobuf-cpp-lite-v29.so" "${2}"
        ;;
		vendor/lib64/hw/camera.qcom.so)
		"${PATCHELF}" --replace-needed "libprotobuf-cpp-full.so" "libprotobuf-cpp-full-v29.so" "${2}"
		;;
		vendor/lib/libgf_hal_G2.so | vendor/lib64/libgf_hal_G2.so | \
		vendor/lib/libgf_hal_G3.so | vendor/lib64/libgf_hal_G3.so | \
		vendor/lib/libgf_hal_G5.so | vendor/lib64/libgf_hal_G5.so )
		    sed -i "s|data/vendor/euclid/version/vendor/firmware|vendor/firmware\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00|g" "${2}"
		    sed -i "s|oppo_version/vendor/firmware|vendor/firmware\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00|g" "${2}"
		;;
	esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

extract_firmware "${MY_DIR}/proprietary-firmware.txt" "${SRC}"

"${MY_DIR}/setup-makefiles.sh"
