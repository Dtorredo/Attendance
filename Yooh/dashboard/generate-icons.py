#!/usr/bin/env python3
from PIL import Image, ImageDraw

def create_logo(size):
    # Create image with transparency
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size // 2
    
    # Create gradient (simplified - using solid iOS blue)
    bg_color = (0, 122, 255, 255)  # iOS Blue
    
    # Background circle
    draw.ellipse([4, 4, size-4, size-4], fill=bg_color)
    
    # School building (white)
    white = (255, 255, 255, 255)
    
    # Main building
    building_width = int(size * 0.4)
    building_height = int(size * 0.35)
    building_x = center - building_width // 2
    building_y = center - building_height // 2 + size // 10
    draw.rectangle([building_x, building_y, building_x + building_width, building_y + building_height], fill=white)
    
    # Roof (triangle)
    roof_points = [
        (center, center - building_height // 2 + size // 20),
        (building_x - size // 20, building_y),
        (building_x + building_width + size // 20, building_y)
    ]
    draw.polygon(roof_points, fill=white)
    
    # Door
    door_width = int(size * 0.12)
    door_height = int(size * 0.2)
    draw.rectangle([center - door_width // 2, center + size // 20, center + door_width // 2, center + door_height], fill=white)
    
    # Windows
    window_size = int(size * 0.08)
    draw.rectangle([building_x + size // 20, building_y + size // 20, building_x + size // 20 + window_size, building_y + size // 20 + window_size], fill=white)
    draw.rectangle([building_x + building_width - size // 12, building_y + size // 20, building_x + building_width - size // 12 + window_size, building_y + size // 20 + window_size], fill=white)
    
    # Graduation cap
    cap_y = center - building_height // 2 - size // 20
    cap_points = [
        (center, cap_y - size // 12),
        (center - size // 4, cap_y),
        (center + size // 4, cap_y)
    ]
    draw.polygon(cap_points, fill=white)
    
    # Save
    img.save(f'logo{size}.png', 'PNG')
    print(f'Created logo{size}.png')

# Generate icons
for size in [512, 192]:
    create_logo(size)

print('✅ Icons generated successfully!')
