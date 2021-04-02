#!/usr/bin/env ruby

require_relative '../src/Bodies.rb'
require_relative '../src/CollisionShapes.rb'
require_relative '../src/DynamicCollisionArbiter.rb'
require_relative '../src/Events.rb'
require_relative '../src/Image.rb'
require_relative '../src/ImageUtils.rb'
require_relative '../src/IntegratorUtils.rb'
require_relative '../src/Rays.rb'
require_relative '../src/Renderer2D.rb'
require_relative '../src/Shapes.rb'
require_relative '../src/StaticCollisionArbiter.rb'
require_relative '../src/Utils.rb'
require_relative '../src/Window.rb'

TITLE = 'Renderer2D - Test_Image_Utils - '

WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 768

FULLSCREEN = false

$window = nil
$renderer = nil
$quit = false

$images = {}

def fhd_to_window_coordinates(hd_x_y, ww_h, fhd_w_h)
	scale_factor = (ww_h*1.0) / fhd_w_h
	return hd_x_y * scale_factor
end

def fhd_circle_radius_to_window_coords(fhd_radius, ww, wh)
	scale_factor = (ww/(wh*1.0))/(1920/1080.0)
	return fhd_radius * scale_factor
end

def setup()
	$window = window_new(TITLE + "Loading...", WINDOW_WIDTH, WINDOW_HEIGHT, FULLSCREEN)
	$renderer = renderer_new($window, ACCELERATION_ON, VSYNC_OFF)
	window_show($window)
	renderer_clear($renderer)
	renderer_flush($renderer)
	
	timer = Utils::Timer.new(1.0, nil)
	timer.start()
	# load image via surface_load + surface_read_pixels + surface_write_pixels and/or RMagick manipulation + surface_to_texture
	# RMagick manipulation
	filepath = '/home/dslaveykov/Downloads/misc/test_cp.jpg'
	image = ImageUtils::image_load(filepath)
	image = ImageUtils::image_blur(image, 200.0, 10.0)
	surface = ImageUtils::image_to_surface(image)
	# direct pixel manipulation
	#pixels = ImageUtils::surface_read(surface)
	#pixels.each do |p|
	#	p[:r] = rand() % 255
	#	p[:g] = rand() % 255
	#	p[:b] = rand() % 255
	#end
	#surface = ImageUtils::surface_write(surface, pixels)
	
	texture = ImageUtils::surface_to_texture($renderer, surface)
	texture_size = ImageUtils::texture_size(texture)
	ImageUtils::surface_delete(surface)
	$images[:surface_load_read_write_output] = {
		x: 0,
		y: 0,
		w: texture_size[:w],
		h: texture_size[:h],
		texture: texture
	}
	
	# load image via texture_load
	filepath = '/home/dslaveykov/Downloads/misc/Sky_Background.png'
	texture = ImageUtils::texture_load($renderer, filepath)
	texture_size = ImageUtils::texture_size(texture)
	$images[:texture_load_output] = {
		x: (WINDOW_WIDTH - texture_size[:w])/2,
		y: 50,
		w: texture_size[:w],
		h: texture_size[:h],
		texture: texture
	}
	
	# load image via surface_load + surface_to_texture (no pixel read)
	filepath = '/home/dslaveykov/Downloads/misc/brick_3.png'
	surface = ImageUtils::surface_load(filepath)
	texture = ImageUtils::surface_to_texture($renderer, surface)
	texture_size = ImageUtils::texture_size(texture)
	ImageUtils::surface_delete(surface)
	$images[:surface_load_output] = {
		x: 639,
		y: 400,
		w: texture_size[:w],
		h: texture_size[:h],
		texture: texture
	}
	timer.update()
	timer.stop()
	puts "Texture's loading took: #{timer.duration().round(2)} seconds!"
end
	
def process_input()
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
end
	
def render_scene()
	$images.each do |k,v|
		$renderer[:impl].copy(v[:texture], nil, SDL2::Rect.new(v[:x], v[:y], v[:w], v[:h]))
	end
	renderer_flush($renderer)
end

def update()
	frame_counter = Utils::frame_counter_new()
	dt = 1.0 / 50
	loop do
		if $quit
			window_hide($window)
			return
		end
		renderer_clear($renderer)
		process_input()
		render_scene()
		counter_data = Utils::update_frame_counter(frame_counter)
		if !counter_data.nil?()
			new_title = "#{TITLE}"
			new_title += "[AVG FPS: #{counter_data[:avg_frames]}] "
			new_title += "[MIN FPS: #{counter_data[:min_frames]}] "
			new_title += "[FPS: #{counter_data[:frames]}] "
			new_title += "[TICKS: #{counter_data[:ticks]}] "
			$window[:impl].title = new_title
		end
		
	end
end
	
def cleanup()
	renderer_delete($renderer)
	window_delete($window)
	$images.each do |k,v|
		ImageUtils::texture_delete(v[:texture])
	end
end
	
def main()
	setup()
	update()		
	cleanup()
end


main()

