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

TITLE = 'Renderer2D - Test_Ray_All_Directions - '

WINDOW_WIDTH = 1024
WINDOW_HEIGHT = 768

FULLSCREEN = false

$window = nil
$renderer = nil
$quit = false
# TODO

# WHETHER THE RAYS WILL BE DRAWN UP TO THE NEAREST CONTANCT POINT (true)
# or not (false)
RAYS_CAN_BE_BLOCKED = true

RAYS_COUNT = 180

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
	
	$shapes = []
    
    $shapes << Shapes::line_new(0, 1, WINDOW_WIDTH, 1)
    $shapes << Shapes::line_new(0, WINDOW_HEIGHT-1, WINDOW_WIDTH, WINDOW_HEIGHT-1)
    $shapes << Shapes::line_new(1, 1, 1, WINDOW_HEIGHT-1)
    $shapes << Shapes::line_new(WINDOW_WIDTH-1, 1, WINDOW_WIDTH-1, WINDOW_HEIGHT-1)
    
    10.times do |i|
		$shapes << Shapes::square_new(rand(WINDOW_WIDTH - 200), rand(WINDOW_HEIGHT - 200), 50)
    end
    
    $edges = []
    $shapes.each do |s|
		$edges << s[:edges]
		$edges.flatten!()
    end
    
    $orig_rays = Rays::ray_cast2(0, 0, 1300, RAYS_COUNT)
    $rays = []
    $cps = []
end

def process_input()
	$cps.clear()
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
	mpos = Events::mouse_position()
	
	dx = mpos[:x] - $orig_rays[0][:x1]
	dy = mpos[:y] - $orig_rays[0][:y1]
	
	newx1 = mpos[:x]
	newy1 = mpos[:y]
	
	$rays.clear()
	$orig_rays.each do |r|
		################
		newx2 = r[:x2] + dx
		newy2 = r[:y2] + dy
		new_ray = {x1: newx1,y1: newy1,x2: newx2,y2: newy2}
		$rays << new_ray
		# get contact points
		cps = Rays::ray_edges_contact_points(new_ray, $edges)
		if RAYS_CAN_BE_BLOCKED
			next if cps[:all_points].length() == 0
			ncp = cps[:all_points][cps[:nearest_point_idx]]
			$cps << ncp
			new_ray[:x2] = ncp[:x]
			new_ray[:y2] = ncp[:y]
		else
			cps[:all_points].each do |cp|
				$cps << cp
			end
		end
		################
	end
end
	
def render_scene()
	$shapes.each do |s|
		renderer_draw_shape($renderer, s, COLOR_WHITE)
	end
	$rays.each do |r|
		renderer_draw_line($renderer, r[:x1], r[:y1], r[:x2], r[:y2], change_color_alpha(	COLOR_WHITE, 100))
	end
	#$cps.each_index do |i|
	#	cp = $cps[i]
	#	renderer_draw_circle($renderer, cp[:x], cp[:y], 1.0, COLOR_YELLOW)
	#end
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
		renderer_set_target_texture($renderer, $screen_texture)
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
			new_title += "[RAYS: #{$rays.length()}] "
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

