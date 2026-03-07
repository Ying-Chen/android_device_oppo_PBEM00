#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=PBEM00
VENDOR=oppo

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

# If XML files don't have comments before the XML header, use this flag
# Can still be used with broken XML files by using blob_fixup
export TARGET_DISABLE_XML_FIXING=true

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_FIRMWARE=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-firmware)
            ONLY_FIRMWARE=true
            ;;
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
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
	    vendor/lib64/hw/camera.qcom.so)
            [ "$2" = "" ] && return 0
	        "${PATCHELF}" --replace-needed "libsnsapi.so" "libsnsapi-v29.so" "${2}"
	    ;;
		# Patch libs to load versioned libprotobuf from SDK 29, as SDK 32 removed some symbols
        vendor/lib64/libwvhidl.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed "libprotobuf-cpp-lite.so" "libprotobuf-cpp-lite-v29.so" "${2}"
        ;;
		vendor/lib64/hw/camera.qcom.so)
            [ "$2" = "" ] && return 0
		    "${PATCHELF}" --replace-needed "libprotobuf-cpp-full.so" "libprotobuf-cpp-full-v29.so" "${2}"
		;;
		vendor/lib/libsl_fp_impl.so | vendor/lib64/libsl_fp_impl.so | \
		vendor/lib/libsl_fp_impl_16bit.so | vendor/lib64/libsl_fp_impl.so | \
		vendor/lib/libgf_hal_G2.so | vendor/lib64/libgf_hal_G2.so | \
		vendor/lib/libgf_hal_G3.so | vendor/lib64/libgf_hal_G3.so | \
		vendor/lib/libgf_hal_G5.so | vendor/lib64/libgf_hal_G5.so )
            [ "$2" = "" ] && return 0
		    sed -i "s|data/vendor/euclid/version/vendor/firmware|vendor/firmware\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00|g" "${2}"
		    sed -i "s|oppo_version/vendor/firmware|vendor/firmware\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00|g" "${2}"
		;;
        *)
            return 1
        ;;
	esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

if [ -z "${ONLY_FIRMWARE}" ]; then
    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
