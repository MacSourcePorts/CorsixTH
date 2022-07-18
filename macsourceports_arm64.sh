# game/app specific values
export APP_VERSION="0.66"
export ICONSDIR="CorsixTH"
export ICONSFILENAME="Icon"
export PRODUCT_NAME="CorsixTH"
export EXECUTABLE_NAME="CorsixTH"
export PKGINFO="APPLCTH"
export COPYRIGHT_TEXT="Theme Hospital © 1997 Bullfrog Productions. All rights reserved."

#constants
source ../MSPScripts/constants.sh
source ../MSPScripts/signing_values.local

export PRE_NOTARIZED_ZIP="${PRODUCT_NAME}_prenotarized.zip"
export POST_NOTARIZED_ZIP="${PRODUCT_NAME}_notarized_$(date +"%Y-%m-%d").zip"
export POST_NOTARIZED_ZIP_ARM64="arm64/${PRODUCT_NAME}-arm64_notarized_$(date +"%Y-%m-%d").zip"
export ENTITLEMENTS_FILE="CorsixTH.entitlements"
export HIGH_RESOLUTION_CAPABLE="true"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "SCRIPT_DIR: " ${SCRIPT_DIR}

rm -rf ${BUILT_PRODUCTS_DIR}
mkdir -p ${BUILT_PRODUCTS_DIR}/arm64

# create makefiles with cmake, perform builds with make
rm -rf ${ARM64_BUILD_FOLDER}
mkdir ${ARM64_BUILD_FOLDER}
cd ${ARM64_BUILD_FOLDER}
cmake \
.. \
-DDISABLE_WERROR=1 \
-DCMAKE_OSX_ARCHITECTURES=arm64  \
-DCMAKE_INSTALL_PREFIX=${SCRIPT_DIR}/${BUILT_PRODUCTS_DIR} \
-DWITH_LUAROCKS=on \
-DCMAKE_OSX_DEPLOYMENT_TARGET=10.12 \
-DLUA_LIBRARY=/opt/Homebrew/lib/liblua.5.4.dylib \
-DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
make CorsixTH -j8
make install

cd ..

codesign --force --timestamp --options runtime --sign "${SIGNING_IDENTITY}" ${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Resources/ssl.so
codesign --force --timestamp --options runtime --sign "${SIGNING_IDENTITY}" ${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Resources/lpeg.so
codesign --force --timestamp --options runtime --sign "${SIGNING_IDENTITY}" ${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Resources/lfs.so
codesign --force --timestamp --options runtime --sign "${SIGNING_IDENTITY}" ${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Resources/mime/core.so
codesign --force --timestamp --options runtime --sign "${SIGNING_IDENTITY}" ${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Contents/Resources/socket/core.so

#sign and notarize
"../MSPScripts/sign_and_notarize.sh" "$1" entitlements

mv ${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME} ${BUILT_PRODUCTS_DIR}/arm64/${WRAPPER_NAME}
if [ "$1" == "notarize" ]; then
    mv ${BUILT_PRODUCTS_DIR}/${PRE_NOTARIZED_ZIP} ${BUILT_PRODUCTS_DIR}/arm64/${PRE_NOTARIZED_ZIP}
    mv ${BUILT_PRODUCTS_DIR}/${POST_NOTARIZED_ZIP} ${BUILT_PRODUCTS_DIR}/${POST_NOTARIZED_ZIP_ARM64}
fi