#!/usr/bin/env ruby

require_relative '../src/Utils.rb'
require_relative '../src/Window.rb'
require_relative '../src/Renderer2D.rb'
require_relative '../src/Events.rb'
require_relative '../src/Shapes.rb'
require_relative '../src/Bodies.rb'
require_relative '../src/IntegratorUtils.rb'

TITLE = 'Renderer2D - Test_Bodies - '

WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 768

FULLSCREEN = false

SHAPE_TO_BODY = 0
BODY_TO_SHAPE = 1

$window = nil
$renderer = nil
$quit = false

$shapes = {}
$bodies = {}

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
	
	$shapes[:player] = {
		shape: Shapes::circle_new(100, 100, 50.0, 32),
		color: COLOR_WHITE
	}
	$bodies[:player] = Bodies::body_dynamic_new(100, 100, 0, 0, 10.0, 10.0, 1.0)
	
	
	$shapes[:enemy] = {
		shape: Shapes::circle_new(500, 500, 50.0, 32),
		color: COLOR_GREEN
	}
	$bodies[:enemy] = Bodies::body_dynamic_new(500, 500, 0, 0, 0.01, 0.01, 1.0)
end
	
def process_input()
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
	
	Bodies::body_apply_impulse($bodies[:player], -100.0, 0) if Events::keyboard_key_pressed?("left")
	Bodies::body_apply_impulse($bodies[:player], 100.0, 0) if Events::keyboard_key_pressed?("right")
	
	Bodies::body_apply_impulse($bodies[:player], 0, -100.0) if Events::keyboard_key_pressed?("up")
	Bodies::body_apply_impulse($bodies[:player], 0, 100.0) if Events::keyboard_key_pressed?("down")
end

def step_bodies(bodies, dt)
	bodies.each do |id, b|
		stepped_values = IntegratorUtils::explicit_euler(dt, b[:px], b[:py], b[:vx], b[:vy], b[:fx], b[:fy], b[:m])
		b[:px] = stepped_values[:px]
		b[:py] = stepped_values[:py]
		
		b[:vx] = stepped_values[:vx]
		b[:vy] = stepped_values[:vy]
		Bodies::body_limit_velocity(b)
		
		# clear forces
		b[:fx] = 0
		b[:fy] = 0
	end
end

def sync_shapes_and_bodies(orienation, shapes, bodies)
	$bodies.each do |id, b|
		shape = $shapes[id][:shape]
		dx = b[:px] - shape[:centroid][:x]
		dy = b[:py] - shape[:centroid][:y]
		Shapes::shape_translate(shape, dx, dy)
	end
end
	
def render_scene(shapes)
	shapes.each do |k,v|
		shape = v[:shape]
		color = v[:color]
		renderer_draw_shape($renderer, shape, color)
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
		step_bodies($bodies, dt)
		sync_shapes_and_bodies(BODY_TO_SHAPE, $shapes, $bodies)
		render_scene($shapes)
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

