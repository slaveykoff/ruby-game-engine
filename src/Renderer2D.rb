#!/usr/bin/env ruby

require_relative './Utils.rb'
require_relative './Window.rb'


require 'sdl2'


COLOR_RED     = [255,   0,       0,   255]
COLOR_GREEN   = [0,     255,     0,   255]
COLOR_BLUE    = [0,     0,     255,   255]

COLOR_WHITE   = [255, 255,     255,   255]
COLOR_BLACK   = [0,     0,       0,     0]

COLOR_CYAN    = [0,     255,   255,   255]
COLOR_MAGENTA = [255,   0,     255,   255]
COLOR_YELLOW  = [255,   255,     0,   255]



ACCELERATION_ON = true
ACCELERATION_OFF = false

VSYNC_ON = true
VSYNC_OFF = false

SUPPORT_TARGET_TEXTURE = true
NO_SUPPORT_TARGET_TEXTURE = false


# it is expected the color's format to be RGBA
def change_color_alpha(src_color, a)
	a_color = []
	a_color << src_color[0]
	a_color << src_color[1]
	a_color << src_color[2]
	a_color << a
	return a_color
end

def color_to_rgba_string(color)
	return "rgba(#{color[0]}, #{color[1]}, #{color[2]}, #{color[3]})"
end

def renderer_new(window, accelerated, vsync, index = -1, supports_target_textures = NO_SUPPORT_TARGET_TEXTURE)
	flags = (vsync) ? SDL2::Renderer::Flags::PRESENTVSYNC : 0
	flags |= (accelerated) ? SDL2::Renderer::Flags::ACCELERATED : SDL2::Renderer::Flags::SOFTWARE
	flags |= (supports_target_textures) ? SDL2::Renderer::Flags::TARGETTEXTURE : 0
	
	renderer = {
		impl:        window[:impl].create_renderer(index, flags),
		vsync:       vsync,
		accelerated: accelerated
	}
	
	return renderer
end

def renderer_delete(r)
	r = nil
end

# blend_mode = SDL2::BlendMode::ADD  if you want your color to have alpha value
# by default it is SDL2::BlendMode::NONE
# which means that COLOR = [255,255,255,255] and COLOR = [255,255,255,0] are the same (the alpha is not used)
def renderer_set_blend_mode(r, blend_mode)
	r[:impl].draw_blend_mode = blend_mode
end

# nill means the screen is the target texture
def renderer_set_target_texture(r, texture)
	r[:impl].render_target = texture
end

def renderer_get_target_texture(r)
	return r[:impl].render_target
end

def renderer_clear(r)
	r[:impl].clear()
end

def renderer_flush(r)
	r[:impl].present()
end

# TEXTURE/SURFACE RELATED METHODS START
# This method must not be here!
def renderer_surface_load(renderer, filepath)
	surface = SDL2::Surface::load(filepath)
	return texture
end

def renderer_texture_load(renderer, filepath)
	texture = renderer[:impl].load_texture(filepath)
	return texture
end

def renderer_target_texture_new(renderer, w, h, format = SDL2::PixelFormat::RGBA8888, color = COLOR_BLACK)
	# possibly add blend mode if needed
	texture = renderer[:impl].create_texture(format, SDL2::Texture::ACCESS_TARGET, w, h)
	render_target = renderer_get_target_texture($renderer)
	renderer_set_target_texture($renderer, texture)
	renderer_clear($renderer)
	renderer_flush($renderer)
	renderer_set_target_texture($renderer, nil)
	return texture
end

def renderer_surface_to_texture(renderer, surface, destroy_surface = false)
	texture = renderer[:impl].create_texture_from(surface)
	surface.destroy() if destroy_surface
	return texture
end

def renderer_draw_texture(renderer, texture, x, y, w, h)
	renderer[:impl].copy(texture, nil, SDL2::Rect.new(x, y, w, h))
end

def renderer_draw_texture2(renderer, texture, x = 0, y = 0)
	renderer_draw_texture(renderer, texture, x, y, texture.w, texture.h)
end
# TEXTURE/SURFACE RELATED METHODS END

def renderer_draw_point(r, x, y, c)
	draw_color = r[:impl].draw_color
	r[:impl].draw_color = c

	r[:impl].draw_point(x, y)
	
	r[:impl].draw_color = draw_color
end

def renderer_draw_circle(re, x, y, r, c, s = 16)
	old_color = re[:impl].draw_color
	
	re[:impl].draw_color = c

	# Draw using midpoint alg
	#_midpoint_circle_drawing(re, cx, cy, r, c)
	# Draw using Bresenham’s alg
	#_bresenham_circle_drawing(re, cx, cy, r, c)
	# Draw using polygon
	_poly_circle_drawing(re, x, y, r, c, s)
	
	re[:impl].draw_color = old_color
end

def renderer_draw_line(r, x1, y1, x2, y2, c)
	draw_color = r[:impl].draw_color
	r[:impl].draw_color = c

	r[:impl].draw_line(x1, y1, x2, y2)
	
	r[:impl].draw_color = draw_color
end

def renderer_draw_triangle(r, x1, y1, x2, y2, x3, y3, c)
	renderer_draw_line(r, x1, y1, x2, y2, c)
	renderer_draw_line(r, x2, y2, x3, y3, c)
	renderer_draw_line(r, x3, y3, x1, y1, c)
end

def renderer_draw_square(r, x, y, s, c)
	renderer_draw_rect(r, x, y, s, s, c)
end

def renderer_draw_rect(r, x, y, w, h, c)
	x1 = x
	y1 = y
	
	x2 = x+w
	y2 = y
	
	x3 = x+w
	y3 = y+h
	
	x4 = x
	y4 = y+h
	
	renderer_draw_quad(r, x1, y1, x2, y2, x3, y3, x4, y4, c)
end

def renderer_draw_quad(r, x1, y1, x2, y2, x3, y3, x4, y4, c)
	renderer_draw_line(r, x1, y1, x2, y2, c)
	renderer_draw_line(r, x2, y2, x3, y3, c)
	renderer_draw_line(r, x3, y3, x4, y4, c)
	renderer_draw_line(r, x4, y4, x1, y1, c)
end

def renderer_draw_poly(r, points, c)
	points.each_index do |i|
		
		p1 = points[i]
		i += 1
		if i >= points.size()
			i = 0
		end
		p2 = points[i]
		
		x1 = p1[:x]
		y1 = p1[:y]
	
		x2 = p2[:x]
		y2 = p2[:y]
		
		renderer_draw_line(r, x1, y1, x2, y2, c)
		
		break if i == 0
	end
end



# may need to unfreeze the object
# renderer, poly, color
def renderer_draw_shape(r, s, c)
	return if s.nil?()
	
	draw_color = r[:impl].draw_color
	r[:impl].draw_color = c
		
	if s[:edges].nil?()
		puts "NO EDGES!"
		exit 1
	end
		
	s[:edges].each do |e|
		x1 = e[:x1]
		y1 = e[:y1]
		x2 = e[:x2]
		y2 = e[:y2]
		
		r[:impl].draw_line(x1, y1, x2, y2)
	end
	
	r[:impl].draw_color = draw_color
end

# renderer, poly, color
def renderer_fill_shape(r, s, c)
	return if s.nil?()

	draw_color = r[:impl].draw_color
	r[:impl].draw_color = c
	s[:filling_lines].each do |f|
		x1 = f[:x1]
		y1 = f[:y1]
		x2 = f[:x2]
		y2 = f[:y2]
		
		r[:impl].draw_line(x1, y1, x2, y2)
	end
	r[:impl].draw_color = draw_color
end

def renderer_draw_collision_shape(r, s, c)
	return if s.nil?()
	
	renderer_draw_collision_circle(r, s[:x], s[:y], s[:r], c)                    if CollisionShapes::collision_shape?(s, CollisionShapes::CS_CIRCLE)
	renderer_draw_collision_aabb(r, s[:x], s[:y], s[:hw], s[:hh], c)             if CollisionShapes::collision_shape?(s, CollisionShapes::CS_AABB)
	renderer_draw_collision_capsule(r, s[:x1], s[:y1], s[:x2], s[:y2], s[:r], c) if CollisionShapes::collision_shape?(s, CollisionShapes::CS_CAPSULE)
	renderer_draw_collision_polygon(r, s[:points], c)                            if CollisionShapes::collision_shape?(s, CollisionShapes::CS_POLYGON)
end

def renderer_draw_collision_circle(re, cx, cy, r, c, s = 32)
	old_color = re[:impl].draw_color
	
	re[:impl].draw_color = c

	# Draw using midpoint alg
	#_midpoint_circle_drawing(re, cx, cy, r, c)
	# Draw using Bresenham’s alg
	#_bresenham_circle_drawing(re, cx, cy, r, c)
	# Draw using polygon
	_poly_circle_drawing(re, cx, cy, r, c, s)
	
	re[:impl].draw_color = old_color
end

def renderer_draw_collision_aabb(re, x, y, hw, hh, c)
	renderer_draw_rect(re, x - hw, y - hh, hw*2, hh*2, c)
end

def renderer_draw_collision_capsule(re, x1, y1, x2, y2, r, c)
	renderer_draw_collision_circle(re, x1, y1, r, c)
	
	n = Utils::normal_to_edge(x1, y1, x2, y2)
	
	renderer_draw_line(re, x1 + (r*n[:x]), y1 + (r*n[:y]), x2 + (r*n[:x]), y2 + (r*n[:y]), c)
	
	renderer_draw_line(re, x1, y1, x2, y2, c)
	
	renderer_draw_line(re, x1 - (r*n[:x]), y1 - (r*n[:y]), x2 - (r*n[:x]), y2 - (r*n[:y]), c)
	
	renderer_draw_collision_circle(re, x2, y2, r, c)
end

def renderer_draw_collision_polygon(re, points, c)
	renderer_draw_poly(re, points, c)
end

def renderer_fill_collision_polygon(re, points, c)
	shape_poly = poly_new(points)
	renderer_fill_shape(re, shape_poly, c)
end

private

def _midpoint_circle_drawing(re, cx, cy, r, c)
	x = r
	y = 0
      
    # When radius is zero only a single 
    # point will be printed 
    if r > 0
		re[:impl].draw_point(x + cx, -y + cy)
		re[:impl].draw_point(y + cx, x + cy)
		re[:impl].draw_point(-y + cx, x + cy)
	end
      
    # Initialising the value of p
    p = 1 - r
    loop do
		break if !(x > y)
		y += 1
		if p <= 0
			p = p + 2*y + 1
		else
			x -= 1
			p = p + 2*y - 2*x + 1
		end
		
		break if x < y
		
		re[:impl].draw_point(x + cx, y + cy)
		re[:impl].draw_point(-x + cx, y + cy)
		re[:impl].draw_point(x + cx, -y + cy)
		re[:impl].draw_point(-x + cx, -y + cy)
        
		if x != y
			re[:impl].draw_point(y + cx, x + cy)
			re[:impl].draw_point(-y + cx, x + cy)
			re[:impl].draw_point(y + cx, -x + cy)
			re[:impl].draw_point(-y + cx, -x + cy)
		end
	end
end

def _bresenham_circle_drawing(re, cx, cy, r, c)
	x = 0
	y = r
	d = 3 - 2*r
	
	re[:impl].draw_point(cx + x, cy + y)
    re[:impl].draw_point(cx - x, cy + y)
    re[:impl].draw_point(cx + x, cy - y)
    re[:impl].draw_point(cx - x, cy - y)
    re[:impl].draw_point(cx + y, cy + x)
    re[:impl].draw_point(cx - y, cy + x)
    re[:impl].draw_point(cx + y, cy - x)
    re[:impl].draw_point(cx - y, cy - x)
	
	loop do
		break if !(y >= x)
		x+= 1
		if d > 0
			y -= 1
			d = d + 4 * (x - y) + 10
		else
			d = d + 4 * x + 6
		end
		re[:impl].draw_point(cx + x, cy + y)
		re[:impl].draw_point(cx - x, cy + y)
		re[:impl].draw_point(cx + x, cy - y)
		re[:impl].draw_point(cx - x, cy - y)
		re[:impl].draw_point(cx + y, cy + x)
		re[:impl].draw_point(cx - y, cy + x)
		re[:impl].draw_point(cx + y, cy - x)
		re[:impl].draw_point(cx - y, cy - x)
	end
end

# Taken from Ruby2D DrawCircle() implementation
def _poly_circle_drawing(re, cx, cy, r, c, sectors = 64) # 32 or 64 looks superb
	angle = 2 * Math::PI / sectors
	prev_i_sin = nil
	prev_i_cos = nil
	Utils::for(0, sectors, Utils::<(), 1, lambda{|i|
		
		cos_i_a = Math::cos(i * angle)
		sin_i_a = Math::sin(i * angle)
			
		if prev_i_cos.nil?()
			prev_i_cos = Math::cos((i - 1) * angle)
		end
		
		if prev_i_sin.nil?()
			prev_i_sin = Math::sin((i - 1) * angle)
		end	
	
		x1 = cx + r * cos_i_a
		y1 = cy + r * sin_i_a
		x2 = cx + r * prev_i_cos
		y2 = cy + r * prev_i_sin
		
		re[:impl].draw_line(x1, y1, x2, y2)
		
		prev_i_sin = sin_i_a
		prev_i_cos = cos_i_a
	})
end
