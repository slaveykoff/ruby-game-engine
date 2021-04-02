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

	
BODY_TO_SHAPE = 0	
SHAPE_TO_BODY = 1

TITLE = 'Renderer2D - Test_Collision_Shapes - '

WINDOW_WIDTH = 1152
WINDOW_HEIGHT = 768

FULLSCREEN = false

$window = nil
$renderer = nil
$quit = false
$collision_shapes_data = {}

$selected_shape_id = nil

def fhd_to_window_coordinates(hd_x_y, ww_h, fhd_w_h)
	scale_factor = (ww_h*1.0) / fhd_w_h
	return hd_x_y * scale_factor
end

def fhd_circle_radius_to_window_coords(fhd_radius, ww, wh)
	scale_factor = (ww/(wh*1.0))/(1920/1080.0)
	return fhd_radius * scale_factor
end

def setup()
	$window = window_new(TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, FULLSCREEN)
	$renderer = renderer_new($window, ACCELERATION_ON, VSYNC_OFF)
	window_show($window)
	renderer_clear($renderer)
	renderer_flush($renderer)	
	$collision_shapes_data[:small_circle] = {
		color: COLOR_GREEN,
		shapes: [CollisionShapes::collision_circle_new(
			fhd_to_window_coordinates(300, WINDOW_WIDTH, 1920),
			fhd_to_window_coordinates(300, WINDOW_HEIGHT, 1080),
			fhd_circle_radius_to_window_coords(100, WINDOW_WIDTH, WINDOW_HEIGHT)
		)]
	}
	triangle_shape = Shapes::triangle_new(
			fhd_to_window_coordinates(500, WINDOW_WIDTH, 1920),
			fhd_to_window_coordinates(100, WINDOW_HEIGHT, 1080),
			fhd_to_window_coordinates(700, WINDOW_WIDTH, 1920),
			fhd_to_window_coordinates(100, WINDOW_HEIGHT, 1080),
			fhd_to_window_coordinates(600, WINDOW_WIDTH, 1920),
			fhd_to_window_coordinates(400, WINDOW_HEIGHT, 1080)
	)
	$collision_shapes_data[:triangle] = {
		color: COLOR_GREEN,
		# *array, expands this array
		shapes: [
			*CollisionShapes::shape_to_collision_shape(triangle_shape, CollisionShapes::CS_CAPSULE),
			CollisionShapes::shape_to_collision_shape(triangle_shape, CollisionShapes::CS_POLYGON)
		]
	}
	$collision_shapes_data[:capsule] = {
		color: COLOR_GREEN,
		shapes: [CollisionShapes::collision_capsule_new(
			fhd_to_window_coordinates(400, WINDOW_WIDTH, 1920),
			fhd_to_window_coordinates(600, WINDOW_HEIGHT, 1080),
			fhd_to_window_coordinates(500, WINDOW_WIDTH, 1920), 
			fhd_to_window_coordinates(700, WINDOW_HEIGHT, 1080),
			fhd_circle_radius_to_window_coords(10, WINDOW_WIDTH, WINDOW_HEIGHT)
		)]
	}
	$collision_shapes_data[:aabb] = {
		color: COLOR_GREEN,
		shapes: [CollisionShapes::collision_aabb_new(
			fhd_to_window_coordinates(650, WINDOW_WIDTH, 1920),
			fhd_to_window_coordinates(650, WINDOW_HEIGHT, 1080),
			fhd_to_window_coordinates(100, WINDOW_WIDTH, 1920),
			fhd_to_window_coordinates(100, WINDOW_HEIGHT, 1080)
		)]
	}
	
	points = []
	points << {
		x: fhd_to_window_coordinates(700, WINDOW_WIDTH, 1080),
		y: fhd_to_window_coordinates(300, WINDOW_HEIGHT, 1080)
	}
	points << {
		x: fhd_to_window_coordinates(800, WINDOW_WIDTH, 1080),
		y: fhd_to_window_coordinates(200, WINDOW_HEIGHT, 1080)
	}
	points << {
		x: fhd_to_window_coordinates(900, WINDOW_WIDTH, 1080),
		y: fhd_to_window_coordinates(300, WINDOW_HEIGHT, 1080)
	}
	points << {
		x: fhd_to_window_coordinates(900, WINDOW_WIDTH, 1080),
		y: fhd_to_window_coordinates(500, WINDOW_HEIGHT, 1080)
	}
	points << {
		x: fhd_to_window_coordinates(700, WINDOW_WIDTH, 1080),
		y: fhd_to_window_coordinates(500, WINDOW_HEIGHT, 1080)
	}
	$collision_shapes_data[:polygon] = {
		color: COLOR_GREEN,
		shapes: [CollisionShapes::collision_polygon_new(points)]
	}
end
	
def process_input()
	$selected_shape_id = nil
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
	# TODO
	
	mpos = Events::mouse_position()
	mpos_shape = CollisionShapes::collision_circle_new(mpos[:x], mpos[:y], 20)	
	#mpos_shape = CollisionShapes::collision_capsule_new(mpos[:x] - 20, mpos[:y] - 10, mpos[:x] + 20, mpos[:y] + 10, 5)
	#mpos_shape = CollisionShapes::collision_aabb_new(mpos[:x], mpos[:y], 25, 25)
	
	renderer_draw_collision_shape($renderer, mpos_shape, COLOR_WHITE)
	
	
	$collision_shapes_data.each do |k, v|
		shapes = v[:shapes]
		has_collision = false
		shapes.each do |s|			
			if CollisionShapes::collide?(s, mpos_shape)
				v[:color] = COLOR_RED
				has_collision = true
				if $selected_shape_id.nil?()
					$selected_shape_id = k
				end
				break
			end
		end
		if !has_collision
			v[:color] = COLOR_GREEN
		end
	end
	
end

def step_bodies(dt)
	# TODO
end

def handle_collisions()
	# TODO
end
	
def render_scene()
	$collision_shapes_data.each do |id, csd|
		color = csd[:color]
		shapes = csd[:shapes]
		shapes.each do |s|
			renderer_draw_collision_shape($renderer, s, color)
			renderer_draw_circle($renderer, s[:centroid][:x], s[:centroid][:y], 5.0, COLOR_YELLOW)
		end
	end
	renderer_flush($renderer)
end
	
def sync_shapes_and_bodies(direction)
	if direction == SHAPE_TO_BODY
		# TODO
	elsif direction == BODY_TO_SHAPE
		# TODO
	else
		throw "Could not sync shapes and bodies. Wrong direction! (#{direction})"
	end
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
		step_bodies(dt)
		sync_shapes_and_bodies(BODY_TO_SHAPE)
		handle_collisions()
		sync_shapes_and_bodies(SHAPE_TO_BODY)
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

