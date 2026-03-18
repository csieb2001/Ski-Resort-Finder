#!/usr/bin/env python3
"""
Marketing Screenshot Generator for Ski Resort Finder
Creates App Store-ready framed screenshots with marketing headlines.

Output sizes:
- iPhone 6.7": 1290 x 2796
- iPhone 6.5": 1284 x 2778
- iPad 12.9":  2048 x 2732
"""

import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(SCRIPT_DIR, "raw")
FRAMED_DIR = os.path.join(SCRIPT_DIR, "framed")

# App Store sizes
SIZES = {
    "iPhone_6.7": (1290, 2796),
    "iPhone_6.5": (1284, 2778),
    "iPad_12.9": (2048, 2732),
}

# Screenshot configs: (filename, headline_de, headline_en, subtitle_de, subtitle_en)
SCREENSHOTS = [
    (
        "01_home.png",
        "Finde dein perfektes\nSkigebiet",
        "Find Your Perfect\nSki Resort",
        "140+ Skigebiete weltweit",
        "140+ ski resorts worldwide",
    ),
    (
        "06_resort_detail.png",
        "Echte Wetter- und\nSchneedaten",
        "Real Weather &\nSnow Data",
        "Detaillierte Statistiken pro Gebiet",
        "Detailed statistics per resort",
    ),
    (
        "04_resort_picker.png",
        "100+ Skigebiete\nweltweit",
        "100+ Ski Resorts\nWorldwide",
        "Suche nach Ort oder Land",
        "Search by location or country",
    ),
    (
        "08_all_rankings.png",
        "Top Rankings auf\neinen Blick",
        "Top Rankings\nat a Glance",
        "Vergleiche alle Skigebiete",
        "Compare all ski resorts",
    ),
    (
        "05b_top3_hotels.png",
        "Hotels direkt\nam Lift",
        "Hotels Right\non the Slopes",
        "Bewertungen & Unterkuenfte",
        "Ratings & accommodations",
    ),
]

# Color scheme matching the app's dark theme
COLORS = {
    "bg_top": (8, 15, 35),       # Dark navy
    "bg_bottom": (15, 25, 55),   # Slightly lighter navy
    "headline": (255, 255, 255), # White
    "subtitle": (140, 170, 220), # Light blue
    "phone_border": (60, 80, 120), # Grayish blue
    "phone_shadow": (0, 0, 0, 80),  # Semi-transparent black
    "accent": (0, 122, 255),     # iOS blue
}

# Phone frame constants
PHONE_CORNER_RADIUS = 60
PHONE_BORDER_WIDTH = 6
PHONE_BEZEL_TOP = 0  # No extra bezel since screenshots include status bar
PHONE_BEZEL_BOTTOM = 0


def get_font(size, bold=False):
    """Try to load a suitable font, fall back to default."""
    font_paths = [
        # macOS system fonts
        "/System/Library/Fonts/SFPro-Bold.otf" if bold else "/System/Library/Fonts/SFPro-Regular.otf",
        "/System/Library/Fonts/Supplemental/SF-Pro-Display-Bold.otf" if bold else "/System/Library/Fonts/Supplemental/SF-Pro-Display-Regular.otf",
        "/Library/Fonts/SF-Pro-Display-Bold.otf" if bold else "/Library/Fonts/SF-Pro-Display-Regular.otf",
        "/System/Library/Fonts/SFCompact.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]

    for path in font_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue

    # Last resort
    return ImageFont.load_default()


def create_gradient(width, height, color_top, color_bottom):
    """Create a vertical gradient background."""
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)

    for y in range(height):
        ratio = y / height
        r = int(color_top[0] * (1 - ratio) + color_bottom[0] * ratio)
        g = int(color_top[1] * (1 - ratio) + color_bottom[1] * ratio)
        b = int(color_top[2] * (1 - ratio) + color_bottom[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    return img


def add_subtle_glow(img, center_x, center_y, radius, color, intensity=30):
    """Add a subtle radial glow effect."""
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for r in range(radius, 0, -2):
        alpha = int(intensity * (1 - (r / radius) ** 2))
        if alpha > 0:
            bbox = [center_x - r, center_y - r, center_x + r, center_y + r]
            draw.ellipse(bbox, fill=(*color, alpha))

    # Composite
    img_rgba = img.convert("RGBA")
    img_rgba = Image.alpha_composite(img_rgba, overlay)
    return img_rgba.convert("RGB")


def round_corners(img, radius):
    """Round the corners of an image."""
    img = img.convert("RGBA")
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, img.width, img.height], radius=radius, fill=255)
    img.putalpha(mask)
    return img


def create_phone_frame(screenshot_path, canvas_width, canvas_height, headline, subtitle):
    """Create a marketing-framed screenshot."""

    # Load screenshot
    screenshot = Image.open(screenshot_path)

    # Calculate phone dimensions
    # The phone should take up about 65% of the canvas width and be centered
    phone_width = int(canvas_width * 0.62)

    # Scale screenshot to fit phone width (accounting for border)
    inner_width = phone_width - 2 * PHONE_BORDER_WIDTH
    scale = inner_width / screenshot.width
    inner_height = int(screenshot.height * scale)
    phone_height = inner_height + 2 * PHONE_BORDER_WIDTH

    # Ensure phone doesn't exceed canvas height (leave room for text)
    max_phone_height = int(canvas_height * 0.66)
    if phone_height > max_phone_height:
        phone_height = max_phone_height
        inner_height = phone_height - 2 * PHONE_BORDER_WIDTH
        scale = inner_height / screenshot.height
        inner_width = int(screenshot.width * scale)
        phone_width = inner_width + 2 * PHONE_BORDER_WIDTH

    # Resize screenshot
    screenshot_resized = screenshot.resize((inner_width, inner_height), Image.LANCZOS)

    # Create gradient background
    bg = create_gradient(canvas_width, canvas_height, COLORS["bg_top"], COLORS["bg_bottom"])

    # Add subtle glow behind where the phone will be
    phone_x = (canvas_width - phone_width) // 2
    phone_y = canvas_height - phone_height - int(canvas_height * 0.04)
    glow_center_x = canvas_width // 2
    glow_center_y = phone_y + phone_height // 3
    bg = add_subtle_glow(bg, glow_center_x, glow_center_y,
                         int(canvas_width * 0.5), (20, 60, 140), intensity=25)

    # Create phone frame with rounded corners
    # First create the outer frame (border)
    phone_frame = Image.new("RGBA", (phone_width, phone_height), (0, 0, 0, 0))
    phone_draw = ImageDraw.Draw(phone_frame)

    # Draw phone border (outer rounded rect)
    corner_r = int(PHONE_CORNER_RADIUS * scale * 0.8)
    phone_draw.rounded_rectangle(
        [0, 0, phone_width - 1, phone_height - 1],
        radius=corner_r,
        fill=(30, 40, 65, 255),
        outline=COLORS["phone_border"],
        width=PHONE_BORDER_WIDTH
    )

    # Paste screenshot inside the border
    screenshot_rounded = round_corners(screenshot_resized, corner_r - PHONE_BORDER_WIDTH)
    phone_frame.paste(screenshot_rounded,
                      (PHONE_BORDER_WIDTH, PHONE_BORDER_WIDTH),
                      screenshot_rounded)

    # Create drop shadow
    shadow_offset = 15
    shadow_blur = 40
    shadow = Image.new("RGBA", (phone_width + shadow_blur * 2, phone_height + shadow_blur * 2), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [shadow_blur, shadow_blur,
         phone_width + shadow_blur, phone_height + shadow_blur],
        radius=corner_r,
        fill=(0, 0, 0, 100)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=shadow_blur // 2))

    # Composite everything
    bg_rgba = bg.convert("RGBA")

    # Place shadow
    shadow_x = phone_x - shadow_blur + shadow_offset
    shadow_y = phone_y - shadow_blur + shadow_offset
    bg_rgba.paste(shadow, (shadow_x, shadow_y), shadow)

    # Place phone
    bg_rgba.paste(phone_frame, (phone_x, phone_y), phone_frame)

    # Add text
    draw = ImageDraw.Draw(bg_rgba)

    # Headline text
    headline_font_size = int(canvas_width * 0.068)
    headline_font = get_font(headline_font_size, bold=True)

    # Calculate text position (centered above phone)
    text_area_top = int(canvas_height * 0.04)
    text_area_height = phone_y - text_area_top - int(canvas_height * 0.02)

    # Get headline bounding box
    headline_bbox = draw.multiline_textbbox((0, 0), headline, font=headline_font,
                                            align="center", spacing=10)
    headline_height = headline_bbox[3] - headline_bbox[1]
    headline_width = headline_bbox[2] - headline_bbox[0]

    # Subtitle
    subtitle_font_size = int(canvas_width * 0.034)
    subtitle_font = get_font(subtitle_font_size, bold=False)
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_height = subtitle_bbox[3] - subtitle_bbox[1]

    # Total text block height
    text_spacing = int(canvas_height * 0.015)
    total_text_height = headline_height + text_spacing + subtitle_height

    # Center text block vertically in text area
    text_start_y = text_area_top + (text_area_height - total_text_height) // 2

    # Draw headline (centered)
    headline_x = (canvas_width - headline_width) // 2
    draw.multiline_text(
        (headline_x, text_start_y),
        headline,
        font=headline_font,
        fill=COLORS["headline"],
        align="center",
        spacing=10
    )

    # Draw subtitle
    subtitle_y = text_start_y + headline_height + text_spacing
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_x = (canvas_width - subtitle_width) // 2
    draw.text(
        (subtitle_x, subtitle_y),
        subtitle,
        font=subtitle_font,
        fill=COLORS["subtitle"],
    )

    return bg_rgba.convert("RGB")


def main():
    os.makedirs(FRAMED_DIR, exist_ok=True)

    print("=" * 60)
    print("Ski Resort Finder - Marketing Screenshot Generator")
    print("=" * 60)

    for size_name, (width, height) in SIZES.items():
        print(f"\nGenerating {size_name} ({width}x{height})...")
        size_dir = os.path.join(FRAMED_DIR, size_name)
        os.makedirs(size_dir, exist_ok=True)

        for i, (filename, headline_de, headline_en, subtitle_de, subtitle_en) in enumerate(SCREENSHOTS):
            raw_path = os.path.join(RAW_DIR, filename)
            if not os.path.exists(raw_path):
                print(f"  WARNING: {filename} not found, skipping")
                continue

            # Generate German version
            output_name_de = f"{i+1:02d}_de_{os.path.splitext(filename)[0]}.png"
            output_path_de = os.path.join(size_dir, output_name_de)

            result = create_phone_frame(raw_path, width, height, headline_de, subtitle_de)
            result.save(output_path_de, "PNG", optimize=True)
            print(f"  Created: {output_name_de}")

            # Generate English version
            output_name_en = f"{i+1:02d}_en_{os.path.splitext(filename)[0]}.png"
            output_path_en = os.path.join(size_dir, output_name_en)

            result = create_phone_frame(raw_path, width, height, headline_en, subtitle_en)
            result.save(output_path_en, "PNG", optimize=True)
            print(f"  Created: {output_name_en}")

    print("\n" + "=" * 60)
    print("Done! Marketing screenshots saved to:")
    print(f"  {FRAMED_DIR}")
    print("=" * 60)

    # Print summary
    total = 0
    for size_name in SIZES:
        size_dir = os.path.join(FRAMED_DIR, size_name)
        if os.path.exists(size_dir):
            count = len([f for f in os.listdir(size_dir) if f.endswith('.png')])
            total += count
            print(f"  {size_name}: {count} screenshots")
    print(f"  Total: {total} screenshots")


if __name__ == "__main__":
    main()
