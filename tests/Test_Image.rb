#!/usr/bin/env ruby

require_relative '../src/Bodies.rb'
require_relative '../src/CollisionShapes.rb'
require_relative '../src/DynamicCollisionArbiter.rb'
require_relative '../src/Events.rb'
require_relative '../src/Image.rb'
require_relative '../src/IntegratorUtils.rb'
require_relative '../src/Rays.rb'
require_relative '../src/Renderer2D.rb'
require_relative '../src/Shapes.rb'
require_relative '../src/StaticCollisionArbiter.rb'
require_relative '../src/Utils.rb'
require_relative '../src/Window.rb'


TITLE = 'Renderer2D - Test_Image - '

WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 768

FULLSCREEN = false

$window = nil
$renderer = nil
$quit = false
# TODO

def fhd_to_window_coordinates(hd_x_y, ww_h, fhd_w_h)
	scale_factor = (ww_h*1.0) / fhd_w_h
	return hd_x_y * scale_factor
end

def fhd_circle_radius_to_window_coords(fhd_radius, ww, wh)
	scale_factor = (ww/(wh*1.0))/(1920/1080.0)
	return fhd_radius * scale_factor
end


def test_conversions()

	# load image form file
	image = Image::image_load('/home/dslaveykov/Downloads/misc/cyberpunk_peach_drink_by_seerlight_dcjbupg-pre.jpg')
	# convert it to surface
	surface = Image::image_to_surface(image)
	# delete the image
	Image::image_delete(image)
	# convert the surface to a new image
	image = Image::surface_to_image(surface, 16)
	# destroy the surface, as it is not needed anymore
	surface.destroy()
	# convert the image to texture
	background_texture = Image::image_to_texture(image, $renderer)
	$textures << {
		impl: background_texture,
		x: 0,
		y: 0,
		w: WINDOW_WIDTH,
		h: WINDOW_HEIGHT
	}	
	
	# load image form file
	image = Image::image_load('/home/dslaveykov/Downloads/misc/brick_2.png')
	# apply effect to image
	image = Image::image_effect(Image::image_effect(image, :shadow, nil), :sharpen, [10.0, 10.0])
	# convert image to surface
	surface = Image::image_to_surface(image)
	brick_texture = renderer_surface_to_texture($renderer, surface, true)
	$textures << {
		impl: brick_texture,
		x: 50,
		y: 50,
		w: brick_texture.w*4,
		h: brick_texture.h*4
	}

end

def test_alpha_composites()
	
end

def test_pixels_each()
	
	image = Image::image_new(200,200, "rgba(255,255,255,255)")
	
	
	Image::image_pixels_each(image) do |pixel, x, y|
		puts pixel
		Image::image_pixel_write(image, x, y, "red") if x % 2 == 0
		Image::image_pixel_write(image, x, y, "blue") if x % 2 == 1
	end
	
	$textures << {
		impl: Image::image_to_texture(image, $renderer),
		x: 100,
		y: 100,
		w: Image::image_size(image)[:w],
		h: Image::image_size(image)[:h]
	}
	
end

def setup()
	$window = window_new(TITLE + "Loading...", WINDOW_WIDTH, WINDOW_HEIGHT, FULLSCREEN)
	$renderer = renderer_new($window, ACCELERATION_ON, VSYNC_ON)
	window_show($window)
	renderer_clear($renderer)
	renderer_flush($renderer)
	
	$textures = []
	#test_conversions()
	
	#test_alpha_composites()
	test_pixels_each()
end
	
def process_input()
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
	# TODO
end
	
def render_scene()	
	$textures.each do |t|
		renderer_draw_texture($renderer, t[:impl], t[:x], t[:y], t[:w], t[:h])
	end
	renderer_flush($renderer)
end

def update()
	$window[:impl].title = TITLE
	frame_counter = Utils::frame_counter_new()
	dt = 1.0 / 50
	loop do
		if $quit
			window_hide($window)
			return
		end
		renderer_clear($renderer)
		process_input()
		# TODO
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
end
	
def main()
	setup()
	update()		
	cleanup()
end


main()

