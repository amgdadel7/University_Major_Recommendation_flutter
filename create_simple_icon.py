#!/usr/bin/env python3
"""
Create a simple 1024x1024 PNG icon for the app
This creates a temporary icon until the proper SVG is converted
"""
try:
    from PIL import Image, ImageDraw, ImageFont
    import os

    # Create a 1024x1024 image
    size = 1024
    img = Image.new('RGB', (size, size), color='#6B46C1')  # Purple background
    draw = ImageDraw.Draw(img)

    # Draw a simple compass
    center_x, center_y = size // 2, size // 2
    radius = size // 3

    # Draw outer circle
    draw.ellipse([center_x - radius, center_y - radius, 
                  center_x + radius, center_y + radius],
                 outline='white', width=20)

    # Draw inner circle
    inner_radius = radius - 40
    draw.ellipse([center_x - inner_radius, center_y - inner_radius,
                  center_x + inner_radius, center_y + inner_radius],
                 outline='white', width=10)

    # Draw N indicator (North)
    draw.line([center_x, center_y - radius, center_x, center_y - inner_radius],
              fill='white', width=20)
    
    # Draw S indicator (South)
    draw.line([center_x, center_y + radius, center_x, center_y + inner_radius],
              fill='white', width=20)
    
    # Draw E indicator (East)
    draw.line([center_x + radius, center_y, center_x + inner_radius, center_y],
              fill='white', width=20)
    
    # Draw W indicator (West)
    draw.line([center_x - radius, center_y, center_x - inner_radius, center_y],
              fill='white', width=20)

    # Draw center point
    draw.ellipse([center_x - 15, center_y - 15, center_x + 15, center_y + 15],
                 fill='#F59E0B')  # Gold center

    # Get script directory and project root
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Create icons directory if it doesn't exist
    icons_dir = os.path.join(script_dir, 'assets', 'icons')
    os.makedirs(icons_dir, exist_ok=True)

    # Save the image
    output_path = os.path.join(icons_dir, 'app_icon.png')
    img.save(output_path, 'PNG')
    print(f'Created simple icon at: {output_path}')
    print('  You can replace this with a proper PNG converted from app_icon.svg')

except ImportError:
    print("Error: PIL (Pillow) is not installed.")
    print("Install it with: pip install Pillow")
    print("\nAlternatively, you can:")
    print("1. Convert app_icon.svg to PNG using an online tool")
    print("2. Or use the simple icon creation method below")
    print("\nTo install Pillow, run:")
    print("  pip install Pillow")
except Exception as e:
    print(f"Error creating icon: {e}")
    print("\nPlease convert app_icon.svg to PNG manually using an online tool")

