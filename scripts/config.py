#!/usr/bin/env python

import pprint
import plistlib
import yaml
import subprocess

with open("config.yaml", 'rb') as f:
    config = yaml.load(f)

configurations = config['configs']

mappings = {
    'Delicious Beta': "delicious_beta",
    'Delicious Debug': "delicious_dev",
    'Delicious App Store': "delicious_app_store",
    'Pinboard Beta': "pinboard_beta",
    'Pinboard Debug': "pinboard_dev",
    'Pinboard App Store': "pinboard_app_store",
    'Pinboard App Store Debug': "pinboard_app_store_debug",
}

path = "Pushpin.xcodeproj/project.pbxproj"

subprocess.call("plutil -convert xml1 {}".format(path), shell=True)
pl = plistlib.readPlist(path)
root = pl['rootObject']
objects = pl['objects']
keys_to_delete = ['CODE_SIGN_IDENTITY[sdk=iphoneos*]']

project_wide_configuration_id = objects[root]['buildConfigurationList']

def update_build_configuration(build_name, build_configuration):
    try:
        name = mappings[objects[build_configuration]['name']]
    except:
        raise
    else:
        build_settings = objects[build_configuration]['buildSettings']
        if build_name == "Pushpin":
            build_settings['CODE_SIGN_ENTITLEMENTS'] = configurations['app'][name]['entitlements']
            build_settings['CODE_SIGN_IDENTITY'] = configurations['app'][name]['code_sign_identity']
            build_settings['INFOPLIST_FILE'] = configurations['app'][name]['info']
            build_settings['PROVISIONING_PROFILE'] = configurations['app'][name]['profile']
        elif build_name == "PushpinFramework":
            build_settings['INFOPLIST_FILE'] = configurations['framework'][name]['info']
            build_settings['CODE_SIGN_IDENTITY'] = configurations['framework'][name]['code_sign_identity']
            build_settings['PROVISIONING_PROFILE'] = ""
            build_settings['CODE_SIGN_ENTITLEMENTS'] = ""
        elif build_name == "Bookmark Extension":
            build_settings['CODE_SIGN_ENTITLEMENTS'] = configurations['bookmark_extension'][name]['entitlements']
            build_settings['CODE_SIGN_IDENTITY'] = configurations['bookmark_extension'][name]['code_sign_identity']
            build_settings['INFOPLIST_FILE'] = configurations['bookmark_extension'][name]['info']
            build_settings['PROVISIONING_PROFILE'] = configurations['bookmark_extension'][name]['profile']
        elif build_name == "Read Later Extension":
            build_settings['CODE_SIGN_ENTITLEMENTS'] = configurations['read_later_extension'][name]['entitlements']
            build_settings['CODE_SIGN_IDENTITY'] = configurations['read_later_extension'][name]['code_sign_identity']
            build_settings['INFOPLIST_FILE'] = configurations['read_later_extension'][name]['info']
            build_settings['PROVISIONING_PROFILE'] = configurations['read_later_extension'][name]['profile']

        for key in keys_to_delete:
            if key in build_settings:
                del build_settings[key]

        return build_settings

targets = objects[root]['targets']
build_configuration_ids = [project_wide_configuration_id]

build_configurations = objects[project_wide_configuration_id]['buildConfigurations']
for build_configuration in build_configurations:
    pl['objects'][build_configuration]['buildSettings'] = update_build_configuration("Pushpin", build_configuration)

for target in targets:
    data = objects[target]
    build_configuration_id = data['buildConfigurationList']
    build_configurations = objects[build_configuration_id]['buildConfigurations']
    for build_configuration in build_configurations:
        pl['objects'][build_configuration]['buildSettings'] = update_build_configuration(data['name'], build_configuration)

plistlib.writePlist(pl, path)

