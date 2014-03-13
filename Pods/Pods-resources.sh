#!/bin/sh
set -e

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
        echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync -av ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -av "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1"`.mom\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd"
      ;;
    *.xcassets)
      ;;
    /*)
      echo "$1"
      echo "$1" >> "$RESOURCES_TO_COPY"
      ;;
    *)
      echo "${PODS_ROOT}/$1"
      echo "${PODS_ROOT}/$1" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
install_resource "BugshotKit/Resources/Inconsolata.otf"
install_resource "RPSTPasswordManagementAppService/images/official-1pw-icon-set/1P-29.png"
install_resource "RPSTPasswordManagementAppService/images/official-1pw-icon-set/1P-29@2x.png"
install_resource "RPSTPasswordManagementAppService/images/official-1pw-icon-set/1P-50.png"
install_resource "RPSTPasswordManagementAppService/images/official-1pw-icon-set/1P-50@2x.png"
install_resource "RPSTPasswordManagementAppService/images/official-1pw-icon-set/1P-57.png"
install_resource "RPSTPasswordManagementAppService/images/official-1pw-icon-set/1P-57@2x.png"
install_resource "RPSTPasswordManagementAppService/images/official-1pw-icon-set/1P-72.png"
install_resource "RPSTPasswordManagementAppService/images/official-1pw-icon-set/1P-72@2x.png"
install_resource "RPSTPasswordManagementAppService/images/official-1pw-icon-set/1P mono icons"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onepassword_activityIcon.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onepassword_activityIcon@2x.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePassword_v3.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePassword_v3@2x.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePassword_v4.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePassword_v4@2x.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePasswordButton_highlighted.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePasswordButton_highlighted@2x.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePasswordButton_normal.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePasswordButton_normal@2x.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePasswordButton_v4_highlighted.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePasswordButton_v4_highlighted@2x.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePasswordButton_v4_normal.png"
install_resource "RPSTPasswordManagementAppService/images/riposte-icons/onePasswordButton_v4_normal@2x.png"
install_resource "uservoice-iphone-sdk/Resources/uv_article.png"
install_resource "uservoice-iphone-sdk/Resources/uv_article@2x.png"
install_resource "uservoice-iphone-sdk/Resources/uv_default_avatar.png"
install_resource "uservoice-iphone-sdk/Resources/uv_default_avatar@2x.png"
install_resource "uservoice-iphone-sdk/Resources/uv_heart.png"
install_resource "uservoice-iphone-sdk/Resources/uv_heart@2x.png"
install_resource "uservoice-iphone-sdk/Resources/uv_idea.png"
install_resource "uservoice-iphone-sdk/Resources/uv_idea@2x.png"
install_resource "uservoice-iphone-sdk/Resources/uv_logo.png"
install_resource "uservoice-iphone-sdk/Resources/uv_logo@2x.png"
install_resource "uservoice-iphone-sdk/Resources/uv_vote_chicklet.png"
install_resource "uservoice-iphone-sdk/Resources/uv_vote_chicklet@2x.png"
install_resource "uservoice-iphone-sdk/Resources/uv_vote_chicklet_empty.png"
install_resource "uservoice-iphone-sdk/Resources/uv_vote_chicklet_empty@2x.png"
install_resource "uservoice-iphone-sdk/Resources/uv_x.png"
install_resource "uservoice-iphone-sdk/Resources/uv_x@2x.png"
install_resource "uservoice-iphone-sdk/Resources/ca.lproj"
install_resource "uservoice-iphone-sdk/Resources/cs.lproj"
install_resource "uservoice-iphone-sdk/Resources/da.lproj"
install_resource "uservoice-iphone-sdk/Resources/de.lproj"
install_resource "uservoice-iphone-sdk/Resources/el.lproj"
install_resource "uservoice-iphone-sdk/Resources/en-GB.lproj"
install_resource "uservoice-iphone-sdk/Resources/en.lproj"
install_resource "uservoice-iphone-sdk/Resources/es.lproj"
install_resource "uservoice-iphone-sdk/Resources/fi.lproj"
install_resource "uservoice-iphone-sdk/Resources/fr.lproj"
install_resource "uservoice-iphone-sdk/Resources/hr.lproj"
install_resource "uservoice-iphone-sdk/Resources/hu.lproj"
install_resource "uservoice-iphone-sdk/Resources/id.lproj"
install_resource "uservoice-iphone-sdk/Resources/it.lproj"
install_resource "uservoice-iphone-sdk/Resources/ja.lproj"
install_resource "uservoice-iphone-sdk/Resources/ko.lproj"
install_resource "uservoice-iphone-sdk/Resources/ms.lproj"
install_resource "uservoice-iphone-sdk/Resources/nb.lproj"
install_resource "uservoice-iphone-sdk/Resources/nl.lproj"
install_resource "uservoice-iphone-sdk/Resources/pl.lproj"
install_resource "uservoice-iphone-sdk/Resources/pt-PT.lproj"
install_resource "uservoice-iphone-sdk/Resources/pt.lproj"
install_resource "uservoice-iphone-sdk/Resources/ro.lproj"
install_resource "uservoice-iphone-sdk/Resources/ru.lproj"
install_resource "uservoice-iphone-sdk/Resources/sk.lproj"
install_resource "uservoice-iphone-sdk/Resources/sv.lproj"
install_resource "uservoice-iphone-sdk/Resources/th.lproj"
install_resource "uservoice-iphone-sdk/Resources/tr.lproj"
install_resource "uservoice-iphone-sdk/Resources/uk.lproj"
install_resource "uservoice-iphone-sdk/Resources/vi.lproj"
install_resource "uservoice-iphone-sdk/Resources/zh-Hans.lproj"
install_resource "uservoice-iphone-sdk/Resources/zh-Hant.lproj"

rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]]; then
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ `xcrun --find actool` ] && [ `find . -name '*.xcassets' | wc -l` -ne 0 ]
then
  case "${TARGETED_DEVICE_FAMILY}" in 
    1,2)
      TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
      ;;
    1)
      TARGET_DEVICE_ARGS="--target-device iphone"
      ;;
    2)
      TARGET_DEVICE_ARGS="--target-device ipad"
      ;;
    *)
      TARGET_DEVICE_ARGS="--target-device mac"
      ;;  
  esac 
  find "${PWD}" -name "*.xcassets" -print0 | xargs -0 actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${IPHONEOS_DEPLOYMENT_TARGET}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
