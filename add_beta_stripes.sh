#!/bin/bash

convert "Assets/Icon.png" -draw "image over 0,0 57,57 'Assets/Beta-Overlay.png'" "Assets/Icon-beta.png"
convert "Assets/Icon@2x.png" -draw "image over 0,0 114,114 'Assets/Beta-Overlay.png'" "Assets/Icon-beta@2x.png"
convert "Assets/Icon-settings.png" -draw "image over 0,0 29,29 'Assets/Beta-Overlay.png'" "Assets/Icon-settings-beta.png"
convert "Assets/Icon-settings@2x.png" -draw "image over 0,0 58,58 'Assets/Beta-Overlay.png'" "Assets/Icon-settings-beta@2x.png"
convert "Assets/iTunesArtwork.png" -draw "image over 0,0 512,512 'Assets/Beta-Overlay.png'" "Assets/iTunesArtwork-beta.png"
convert "Assets/iTunesArtwork@2x.png" -draw "image over 0,0 1024,1024 'Assets/Beta-Overlay.png'" "Assets/iTunesArtwork-beta@2x.png"

convert "Assets/Icon.png" -draw "image over 0,0 57,57 'Assets/Dev-Overlay.png'" "Assets/Icon-dev.png"
convert "Assets/Icon@2x.png" -draw "image over 0,0 114,114 'Assets/Dev-Overlay.png'" "Assets/Icon-dev@2x.png"
convert "Assets/Icon-settings.png" -draw "image over 0,0 29,29 'Assets/Dev-Overlay.png'" "Assets/Icon-settings-dev.png"
convert "Assets/Icon-settings@2x.png" -draw "image over 0,0 58,58 'Assets/Dev-Overlay.png'" "Assets/Icon-settings-dev@2x.png"
convert "Assets/iTunesArtwork.png" -draw "image over 0,0 512,512 'Assets/Dev-Overlay.png'" "Assets/iTunesArtwork-dev.png"
convert "Assets/iTunesArtwork@2x.png" -draw "image over 0,0 1024,1024 'Assets/Dev-Overlay.png'" "Assets/iTunesArtwork-dev@2x.png"
