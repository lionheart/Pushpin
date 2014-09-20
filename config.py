#!/bin/bash

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
targets = objects[root]['targets']
keys_to_delete = ['CODE_SIGN_IDENTITY[sdk=iphoneos*]']

for target in targets:
    data = objects[target]
    build_configuration_id = data['buildConfigurationList']
    build_configurations = objects[build_configuration_id]['buildConfigurations']
    for build_configuration in build_configurations:
        try:
            name = mappings[objects[build_configuration]['name']]
        except:
            raise
        else:
            build_settings = pl['objects'][build_configuration]['buildSettings']
            if data['name'] == "Pushpin":
                build_settings['CODE_SIGN_ENTITLEMENTS'] = configurations['app'][name]['entitlements']
                build_settings['CODE_SIGN_IDENTITY'] = configurations['app'][name]['code_sign_identity']
                build_settings['INFOPLIST_FILE'] = configurations['app'][name]['info']
                build_settings['PROVISIONING_PROFILE'] = configurations['app'][name]['profile']
            elif data['name'] == "PushpinFramework":
                if 'CODE_SIGN_IDENTITY' in build_settings:
                    del build_settings['CODE_SIGN_IDENTITY']
            elif data['name'] == "Extension":
                build_settings['CODE_SIGN_ENTITLEMENTS'] = configurations['extension'][name]['entitlements']
                build_settings['CODE_SIGN_IDENTITY'] = configurations['extension'][name]['code_sign_identity']
                build_settings['INFOPLIST_FILE'] = configurations['extension'][name]['info']
                build_settings['PROVISIONING_PROFILE'] = configurations['extension'][name]['profile']

            for key in keys_to_delete:
                if key in build_settings:
                    del build_settings[key]

            pl['objects'][build_configuration]['buildSettings'] = build_settings

plistlib.writePlist(pl, path)

