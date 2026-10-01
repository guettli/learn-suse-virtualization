#!/usr/bin/env python3
"""Generates branded application icons, adaptive icon layers, and splash assets for Hands-Free Flashcards."""

import os
import shutil
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
APP_DIR = os.path.join(REPO_ROOT, 'app')
RES_DIR = os.path.join(APP_DIR, 'android', 'app', 'src', 'main', 'res')

# Full standalone icon (legacy launcher & store listing)
FULL_ICON_SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0c322c"/>
      <stop offset="100%" stop-color="#061d19"/>
    </linearGradient>
    <linearGradient id="cardGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="100%" stop-color="#f0fdf4"/>
    </linearGradient>
    <linearGradient id="suseGreen" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#30ba78"/>
      <stop offset="100%" stop-color="#24965e"/>
    </linearGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#000000" flood-opacity="0.45"/>
    </filter>
  </defs>

  <!-- Base Rounded Background -->
  <rect width="512" height="512" rx="112" fill="url(#bgGrad)"/>

  <!-- Back Flashcard (Rotated) -->
  <rect x="120" y="100" width="272" height="312" rx="28" fill="#154a40" stroke="#30ba78" stroke-width="4" transform="rotate(-8 256 256)" opacity="0.85"/>

  <!-- Front Flashcard -->
  <rect x="126" y="106" width="260" height="300" rx="28" fill="url(#cardGrad)" filter="url(#shadow)"/>

  <!-- Card Header Line / Accent -->
  <path d="M 166 150 L 346 150" stroke="#30ba78" stroke-width="8" stroke-linecap="round"/>

  <!-- Headphone Arc Over Card -->
  <path d="M 180 260 A 76 76 0 0 1 332 260" fill="none" stroke="url(#suseGreen)" stroke-width="14" stroke-linecap="round"/>
  <!-- Headphone Left Ear Cup -->
  <rect x="166" y="246" width="22" height="42" rx="10" fill="#0c322c" stroke="#30ba78" stroke-width="4"/>
  <!-- Headphone Right Ear Cup -->
  <rect x="324" y="246" width="22" height="42" rx="10" fill="#0c322c" stroke="#30ba78" stroke-width="4"/>

  <!-- Soundwaves / Speech Dots in Center of Card -->
  <circle cx="230" cy="270" r="7" fill="#0c322c"/>
  <circle cx="256" cy="270" r="10" fill="#30ba78"/>
  <circle cx="282" cy="270" r="7" fill="#0c322c"/>

  <!-- Spaced Repetition Indicator (3 Level Bars: Simple/Medium/Hard) -->
  <rect x="180" y="340" width="40" height="12" rx="6" fill="#30ba78"/>
  <rect x="236" y="340" width="40" height="12" rx="6" fill="#f59e0b"/>
  <rect x="292" y="340" width="40" height="12" rx="6" fill="#ef4444"/>
</svg>
'''

# Transparent foreground for Android Adaptive Icons (centered in 108dp canvas, ~66% safe zone)
FOREGROUND_SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <linearGradient id="cardGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="100%" stop-color="#f0fdf4"/>
    </linearGradient>
    <linearGradient id="suseGreen" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#30ba78"/>
      <stop offset="100%" stop-color="#24965e"/>
    </linearGradient>
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="10" stdDeviation="14" flood-color="#000000" flood-opacity="0.4"/>
    </filter>
  </defs>

  <!-- Scale slightly down to fit inside adaptive icon 72dp safe zone -->
  <g transform="translate(25.6, 25.6) scale(0.9)">
    <!-- Back Flashcard (Rotated) -->
    <rect x="120" y="100" width="272" height="312" rx="28" fill="#154a40" stroke="#30ba78" stroke-width="4" transform="rotate(-8 256 256)" opacity="0.85"/>

    <!-- Front Flashcard -->
    <rect x="126" y="106" width="260" height="300" rx="28" fill="url(#cardGrad)" filter="url(#shadow)"/>

    <!-- Card Header Line / Accent -->
    <path d="M 166 150 L 346 150" stroke="#30ba78" stroke-width="8" stroke-linecap="round"/>

    <!-- Headphone Arc Over Card -->
    <path d="M 180 260 A 76 76 0 0 1 332 260" fill="none" stroke="url(#suseGreen)" stroke-width="14" stroke-linecap="round"/>
    <!-- Headphone Left Ear Cup -->
    <rect x="166" y="246" width="22" height="42" rx="10" fill="#0c322c" stroke="#30ba78" stroke-width="4"/>
    <!-- Headphone Right Ear Cup -->
    <rect x="324" y="246" width="22" height="42" rx="10" fill="#0c322c" stroke="#30ba78" stroke-width="4"/>

    <!-- Soundwaves / Speech Dots in Center of Card -->
    <circle cx="230" cy="270" r="7" fill="#0c322c"/>
    <circle cx="256" cy="270" r="10" fill="#30ba78"/>
    <circle cx="282" cy="270" r="7" fill="#0c322c"/>

    <!-- Spaced Repetition Indicator (3 Level Bars: Simple/Medium/Hard) -->
    <rect x="180" y="340" width="40" height="12" rx="6" fill="#30ba78"/>
    <rect x="236" y="340" width="40" height="12" rx="6" fill="#f59e0b"/>
    <rect x="292" y="340" width="40" height="12" rx="6" fill="#ef4444"/>
  </g>
</svg>
'''

def get_convert_cmd():
    if shutil.which('magick'):
        return ['magick']
    if shutil.which('convert'):
        return ['convert']
    raise RuntimeError("Neither 'magick' nor 'convert' (ImageMagick) found on PATH.")

def render_png(convert_cmd, svg_path, out_path, size):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    cmd = convert_cmd + [
        '-background', 'none',
        '-resize', f'{size}x{size}',
        svg_path,
        out_path,
    ]
    subprocess.run(cmd, check=True)
    print(f"Generated {out_path} ({size}x{size})")

def main():
    convert_cmd = get_convert_cmd()

    full_svg = os.path.join(APP_DIR, 'assets', 'icon.svg')
    fg_svg = os.path.join(APP_DIR, 'assets', 'icon_foreground.svg')
    os.makedirs(os.path.join(APP_DIR, 'assets'), exist_ok=True)

    with open(full_svg, 'w', encoding='utf-8') as f:
        f.write(FULL_ICON_SVG)

    with open(fg_svg, 'w', encoding='utf-8') as f:
        f.write(FOREGROUND_SVG)

    # 1. Legacy Launcher Icons (ic_launcher.png)
    legacy_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for density, size in legacy_sizes.items():
        out = os.path.join(RES_DIR, density, 'ic_launcher.png')
        render_png(convert_cmd, full_svg, out, size)

    # 2. Adaptive Icon Foregrounds (ic_launcher_foreground.png)
    # Android adaptive icons are 108dp x 108dp
    adaptive_sizes = {
        'mipmap-mdpi': 108,
        'mipmap-hdpi': 162,
        'mipmap-xhdpi': 216,
        'mipmap-xxhdpi': 324,
        'mipmap-xxxhdpi': 432,
    }
    for density, size in adaptive_sizes.items():
        out = os.path.join(RES_DIR, density, 'ic_launcher_foreground.png')
        render_png(convert_cmd, fg_svg, out, size)

    # 3. High-Res Store Asset
    store_out = os.path.join(APP_DIR, 'assets', 'app_icon.png')
    render_png(convert_cmd, full_svg, store_out, 512)

    # 4. Splash Screen Raster Graphic (launch_image.png)
    splash_sizes = {
        'drawable': 144,
        'drawable-hdpi': 144,
        'drawable-xhdpi': 192,
        'drawable-xxhdpi': 288,
        'drawable-xxxhdpi': 384,
    }
    for density, size in splash_sizes.items():
        out = os.path.join(RES_DIR, density, 'launch_image.png')
        render_png(convert_cmd, full_svg, out, size)

if __name__ == '__main__':
    main()
