#!/bin/bash

import pprint
import plistlib
import yaml

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

path = "Pushpin.xcodeproj/out.pbxproj"
pl = plistlib.readPlist(path)
root = pl['rootObject']
objects = pl['objects']
targets = objects[root]['targets']

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
            if data['name'] == "Pushpin":
                pl['objects'][build_configuration]['buildSettings']['CODE_SIGN_ENTITLEMENTS'] = configurations['app'][name]['entitlements']
                pl['objects'][build_configuration]['buildSettings']['CODE_SIGN_IDENTITY'] = configurations['app'][name]['code_sign_identity']
                pl['objects'][build_configuration]['buildSettings']['INFOPLIST_FILE'] = configurations['app'][name]['info']
                pl['objects'][build_configuration]['buildSettings']['PROVISIONING_PROFILE'] = configurations['app'][name]['profile']
                del pl['objects'][build_configuration]['buildSettings']['CODE_SIGN_IDENTITY[sdk=iphoneos*]']
            elif data['name'] == "PushpinFramework":
                del pl['objects'][build_configuration]['buildSettings']['CODE_SIGN_IDENTITY[sdk=iphoneos*]']
                del pl['objects'][build_configuration]['buildSettings']['CODE_SIGN_IDENTITY']
            elif data['name'] == "Share Extension":
                pl['objects'][build_configuration]['buildSettings']['CODE_SIGN_ENTITLEMENTS'] = configurations['extension'][name]['entitlements']
                pl['objects'][build_configuration]['buildSettings']['CODE_SIGN_IDENTITY'] = configurations['extension'][name]['code_sign_identity']
                pl['objects'][build_configuration]['buildSettings']['INFOPLIST_FILE'] = configurations['extension'][name]['info']
                pl['objects'][build_configuration]['buildSettings']['PROVISIONING_PROFILE'] = configurations['extension'][name]['profile']
                del pl['objects'][build_configuration]['buildSettings']['CODE_SIGN_IDENTITY[sdk=iphoneos*]']

plistlib.writePlist(pl, "Pushpin.xcodeproj/project.pbxproj")
