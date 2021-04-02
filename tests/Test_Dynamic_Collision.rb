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

TITLE = 'Renderer2D - Test_Dynamic_Collision - '

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
	
	
	$collision_shapes[:circle_a] = CollisionShapes::collision_circle_new(100, 100.01, 50.0)
	$collision_shapes[:circle_b] = CollisionShapes::collision_circle_new(400, 100, 50.0)
	#$collision_shapes[:capsule_a] = CollisionShapes::collision_capsule_new(
	#	500, 300, 700, 300, 10.0
	#)
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
	#$collision_shapes[:polygon_a] = CollisionShapes::collision_polygon_new(points)
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
	#$collision_shapes[:polygon_b] = CollisionShapes::collision_polygon_new(points)
	# specify which shape should be controlled by the mouse
	$movable_shape_id = :circle_b
	$move_x = $move_y = 10.0

	all_bodies_dynamic = true

	$bodies = {}
	$collision_shapes.each do |k,v|
		
		if all_bodies_dynamic
			$bodies[k] = Bodies::body_dynamic_new(
				$collision_shapes[k][:centroid][:x], 
				$collision_shapes[k][:centroid][:y],
				0,0,100,100,
				1.0,
				1.0
			)
		else
			if k.eql?($movable_shape_id)
				$bodies[k] = Bodies::body_dynamic_new(
					$collision_shapes[k][:centroid][:x], 
					$collision_shapes[k][:centroid][:y],
					0,0,100,100,
					1.0,
					1.0
				)
			else
				$bodies[k] = Bodies::body_static_new(
					$collision_shapes[k][:centroid][:x], 
					$collision_shapes[k][:centroid][:y],
					1.0
				)
			end
		end
	end
	
	if $bodies[$movable_shape_id].nil?()
		throw "Movable shape #{$movable_shape_id} is not attached to body!"
	end
end
	
def process_input()
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
	if Events::keyboard_key_pressed?("right")
		Bodies::body_apply_force($bodies[$movable_shape_id], $move_x, 0)
	end
	if Events::keyboard_key_pressed?("left")
		Bodies::body_apply_force($bodies[$movable_shape_id], -$move_x, 0)
	end
	if Events::keyboard_key_pressed?("up")
		Bodies::body_apply_force($bodies[$movable_shape_id], 0, -$move_y)
	end
	if Events::keyboard_key_pressed?("down")
		Bodies::body_apply_force($bodies[$movable_shape_id], 0, $move_y)
	end
end

def step_bodies(dt)
	$bodies.each do |k,v|
		
		old_px = v[:px]
		old_py = v[:py]
	
		i_body = IntegratorUtils::explicit_euler(dt,
			v[:px], v[:py],
			v[:vx], v[:vy],
			v[:fx], v[:fy],
			v[:m]
		)
		Bodies::body_limit_velocity(v)
		v[:px] = i_body[:px]
		v[:py] = i_body[:py]
		v[:vx] = i_body[:vx]
		v[:vy] = i_body[:vy]
		
		Bodies::body_clear_forces(v)
		
		collision_shape = $collision_shapes[k]
		next if collision_shape.nil?()
		
		dx = v[:px] - old_px
		dy = v[:py] - old_py
		
		CollisionShapes::collision_shape_translate(collision_shape, dx, dy)
	end
end

def handle_collisions()

	$collision_shapes.each do |k1,v1|
		b1 = $bodies[k1]
		next if b1.nil?()
		$collision_shapes.each do |k2,v2|
			next if k1.eql?(k2)
			b2 = $bodies[k2]
			next if b2.nil?()
			manifold = DynamicCollisionArbiter::resolve(v1, b1, v2, b2)
			
			next if manifold.nil?()
			
			b1[:px] = v1[:centroid][:x]
			b1[:py] = v1[:centroid][:y]
			
			b2[:px] = v2[:centroid][:x]
			b2[:py] = v2[:centroid][:y]
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
	dt = 1.0 / 50
	frame_counter = Utils::frame_counter_new()
	step_bodies_timer = Utils::Timer.new(dt, -> {
		duration = step_bodies_timer.duration()
		# if the duration between this and the last Timer.update() is more than dt*1.1
		# execute multiple step_bodies until the remaining duration is less than dt
		loop do
			break if duration < dt
			step_bodies(dt)
			duration -= dt
		end
	})
	step_bodies_timer.start()
	loop do
		if $quit
			window_hide($window)
			return
		end
		renderer_clear($renderer)
		process_input()
		#step_bodies(dt)
		step_bodies_timer.update()
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
	step_bodies_timer.stop()
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

