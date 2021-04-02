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


=begin
	TODO: rotate polygon around its centroid!
=end

TITLE = 'Renderer2D - Test_Point_Utils - '

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

def setup()
	$window = window_new(TITLE + "Loading...", WINDOW_WIDTH, WINDOW_HEIGHT, FULLSCREEN)
	$renderer = renderer_new($window, ACCELERATION_ON, VSYNC_OFF)
	window_show($window)
	renderer_clear($renderer)
	renderer_flush($renderer)
	# TODO
	$point = {
		x: 400,
		y: 400
	}
end
	
def process_input()
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
	# TODO
	if Events::keyboard_key_pressed?("right")
		tp = Utils::translate_point($point[:x], $point[:y], 1, 0)
		$point[:x] = tp[:x]
		$point[:y] = tp[:y]
	end
	if Events::keyboard_key_pressed?("left")
		tp = Utils::translate_point($point[:x], $point[:y], -1, 0)
		$point[:x] = tp[:x]
		$point[:y] = tp[:y]
	end
	if Events::keyboard_key_pressed?("up")
		tp = Utils::translate_point($point[:x], $point[:y], 0, -1)
		$point[:x] = tp[:x]
		$point[:y] = tp[:y]
	end
	if Events::keyboard_key_pressed?("down")
		tp = Utils::translate_point($point[:x], $point[:y], 0, 1)
		$point[:x] = tp[:x]
		$point[:y] = tp[:y]
	end
	if Events::keyboard_key_pressed?("q")
		renderer_draw_line($renderer, $point[:x], $point[:y], 500, 500, COLOR_GREEN)
		renderer_draw_point($renderer, 500, 500, COLOR_RED)
		tp = Utils::rotate_point($point[:x], $point[:y], -0.01, 500, 500)
		$point[:x] = tp[:x]
		$point[:y] = tp[:y]
	end
	if Events::keyboard_key_pressed?("e")
		renderer_draw_line($renderer, $point[:x], $point[:y], 500, 500, COLOR_GREEN)
		renderer_draw_point($renderer, 500, 500, COLOR_RED)
		tp = Utils::rotate_point($point[:x], $point[:y], 0.01, 500, 500)
		$point[:x] = tp[:x]
		$point[:y] = tp[:y]
	end
	
	
end
	
def render_scene()
	# TODO
	renderer_draw_point($renderer, $point[:x], $point[:y], COLOR_WHITE)
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

