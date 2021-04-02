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


TITLE = 'Renderer2D - Test_Static_Collision_2 - '

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 480

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
	
	$collision_shapes = {}
	x = 0
	y = 0
	prev_radius = 0
	100.times do |i|
		radius = rand(10) + 1
		x += (radius * 2) + prev_radius
		$collision_shapes["circle_#{i}".to_sym()] = CollisionShapes::collision_circle_new(x, y, radius)
		prev_radius = radius
	end
	
	$collision_shapes[:capsule_a] = CollisionShapes::collision_capsule_new(
		10, 400, WINDOW_WIDTH/2, WINDOW_HEIGHT-10, 10.0
	)
	
	$collision_shapes[:capsule_b] = CollisionShapes::collision_capsule_new(
		WINDOW_WIDTH/2, WINDOW_HEIGHT-10, WINDOW_WIDTH, 400, 10.0
	)
	
	$bodies = {}
	$collision_shapes.each do |k,v|
		if k.eql?(:capsule_a) || k.eql?(:capsule_b)
			$bodies[k] = Bodies::body_static_new(
			$collision_shapes[k][:centroid][:x], 
			$collision_shapes[k][:centroid][:y]
		)
		else
			$bodies[k] = Bodies::body_dynamic_new(
				$collision_shapes[k][:centroid][:x], 
				$collision_shapes[k][:centroid][:y],
				0,0,5000,5000,
				1.0
			)
		end
		
		$gravity = {
			x: 0,
			y: 400
		}
		
	end
end
	
def process_input()
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
	# TODO
end
	
def render_scene()
	$collision_shapes.each do |k,v|
		renderer_draw_collision_shape($renderer, v, COLOR_WHITE)
	end
	renderer_flush($renderer)
end

def step_space()
	dt = 1.0 / 100
	$bodies.each do |k,v|
		next if Bodies::body_static?(v)
		# apply forces
		cpx = v[:px]
		cpy = v[:py]
		Bodies::body_apply_force(v, $gravity[:x], $gravity[:y])
		# integrate position/velocity
		i_data = IntegratorUtils::explicit_euler(
			dt, v[:px], v[:py], v[:vx], v[:vy],
			v[:fx], v[:fy], v[:m]
		)
		v[:px] = i_data[:px]
		v[:py] = i_data[:py]
		v[:vx] = i_data[:vx]
		v[:vy] = i_data[:vy]
		Bodies::body_limit_velocity(v)
		Bodies::body_clear_forces(v)
		# update/translate collision shape for the body
		shape = $collision_shapes[k]
		next if shape.nil?()
		dx = v[:px] - cpx
		dy = v[:py] - cpy
		CollisionShapes::collision_shape_translate(shape, dx, dy)
	end
	
	$collision_shapes.each do |k1,v1|
		b1 = $bodies[k1]
		$collision_shapes.each do |k2,v2|
			next if k1.eql?(k2)
			b2 = $bodies[k2]
			manifold = StaticCollisionArbiter::resolve(v1, b1, v2, b2)
			next if manifold.nil?()
			# this is writtnen here, since the Static Collision arbiter does not change velocities
			b1[:vx] = 0
			b1[:vy] = 0
			
			b2[:vx] = 0
			b2[:vy] = 0
		end
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
		step_space()
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

