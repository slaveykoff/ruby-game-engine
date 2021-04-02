#!/usr/bin/env ruby

require_relative '../src/Bodies.rb'
require_relative '../src/CollisionShapes.rb'
require_relative '../src/Events.rb'
require_relative '../src/Image.rb'
require_relative '../src/IntegratorUtils.rb'
require_relative '../src/Rays.rb'
require_relative '../src/Renderer2D.rb'
require_relative '../src/Shapes.rb'
require_relative '../src/StaticCollisionArbiter.rb'
require_relative '../src/Utils.rb'
require_relative '../src/Window.rb'

TITLE = 'Renderer2D - Test_Static_Collision - '

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

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
	
	$collision_shapes = {}
	
	
	#$collision_shapes[:circle_a] = CollisionShapes::collision_circle_new(100, 100, 50.0)
	#$collision_shapes[:circle_b] = CollisionShapes::collision_circle_new(400, 100, 50.0)
	$collision_shapes[:capsule_a] = CollisionShapes::collision_capsule_new(
		500, 300, 700, 300, 10.0
	)
	#$collision_shapes[:capsule_b] = CollisionShapes::collision_capsule_new(
	#	100, 300, 300, 400, 10.0
	#)
	#$collision_shapes[:aabb_a] = CollisionShapes::collision_aabb_new(
	#	500, 500, 100, 100
	#)
	#$collision_shapes[:aabb_b] = CollisionShapes::collision_aabb_new(
	#	300, 600, 75, 50
	#)
	# Thing that does not work
	# 1. CAPSULE vs POLYGON
	# 2. AABB vs POLYGON
	# 3. POLYGON vs POLYGON
	points = []
	points << {
		x: 800,
		y: 300
	}
	points << {
		x: 900,
		y: 100
	}
	points << {
		x: 1000,
		y: 300
	}
	points << {
		x: 1000,
		y: 500
	}
	points << {
		x: 900,
		y: 400
	}
	points << {
		x: 800,
		y: 500
	}
	$collision_shapes[:polygon_a] = CollisionShapes::collision_polygon_new(points)
	points.clear()
	points << {
		x: 10,
		y: 10
	}
	points << {
		x: 50,
		y: 30
	}
	points << {
		x: 40,
		y: 50
	}
	points << {
		x: 20,
		y: 60
	}
	$collision_shapes[:polygon_b] = CollisionShapes::collision_polygon_new(points)

	# specify which shape should be controlled by the mouse
	$movable_shape_id = :capsule_a
	$move_x = $move_y = 5.0

	$bodies = {}
	$collision_shapes.each do |k,v|
		if k.eql?($movable_shape_id)
			$bodies[k] = Bodies::body_dynamic_new(
				$collision_shapes[k][:centroid][:x], 
				$collision_shapes[k][:centroid][:y],
				0,0,100,100,
				1.0
			)
		else
			$bodies[k] = Bodies::body_static_new(
				$collision_shapes[k][:centroid][:x], 
				$collision_shapes[k][:centroid][:y]
			)
		end
	end
end
	
def process_input()
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
	if Events::keyboard_key_pressed?("right")
		CollisionShapes::collision_shape_translate($collision_shapes[$movable_shape_id], $move_x, 0)
		$bodies[$movable_shape_id][:px] = $collision_shapes[$movable_shape_id][:x]
		$bodies[$movable_shape_id][:py] = $collision_shapes[$movable_shape_id][:y]
	end
	if Events::keyboard_key_pressed?("left")
		CollisionShapes::collision_shape_translate($collision_shapes[$movable_shape_id], -$move_x, 0)
		$bodies[$movable_shape_id][:px] = $collision_shapes[$movable_shape_id][:x]
		$bodies[$movable_shape_id][:py] = $collision_shapes[$movable_shape_id][:y]
	end
	if Events::keyboard_key_pressed?("up")
		CollisionShapes::collision_shape_translate($collision_shapes[$movable_shape_id], 0, -$move_y)
		$bodies[$movable_shape_id][:px] = $collision_shapes[$movable_shape_id][:x]
		$bodies[$movable_shape_id][:py] = $collision_shapes[$movable_shape_id][:y]
	end
	if Events::keyboard_key_pressed?("down")
		CollisionShapes::collision_shape_translate($collision_shapes[$movable_shape_id], 0, $move_y)
		$bodies[$movable_shape_id][:px] = $collision_shapes[$movable_shape_id][:x]
		$bodies[$movable_shape_id][:py] = $collision_shapes[$movable_shape_id][:y]
	end
end

def handle_collisions()

	$collision_shapes.each do |k1,v1|
		b1 = $bodies[k1]
		$collision_shapes.each do |k2,v2|
			next if k1.eql?(k2)
			b2 = $bodies[k2]
			manifold = StaticCollisionArbiter::resolve(v1, b1, v2, b2)
		end
	end

end
	
def render_scene()	
	$collision_shapes.each do |k,v|
		renderer_draw_collision_shape($renderer, v, COLOR_WHITE)
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
		handle_collisions()
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

