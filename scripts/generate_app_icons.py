#!/usr/bin/env python3
"""Generates branded application icons and splash assets for Hands-Free Flashcards."""

import os
import subprocess

SVG_CONTENT = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
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

SIZES = {
    'app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    'app/assets/app_icon.png': 512,
}

def main():
    svg_path = 'app/assets/icon.svg'
    os.makedirs('app/assets', exist_ok=True)
    with open(svg_path, 'w', encoding='utf-8') as f:
        f.write(SVG_CONTENT)

    for out_path, size in SIZES.items():
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        cmd = [
            'convert',
            '-background', 'none',
            '-resize', f'{size}x{size}',
            svg_path,
            out_path,
        ]
        subprocess.run(cmd, check=True)
        print(f"Generated {out_path} ({size}x{size})")

if __name__ == '__main__':
    main()
