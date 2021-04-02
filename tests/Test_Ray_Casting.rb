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

TITLE = 'Renderer2D - Test_Ray_Casting - '

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
	renderer_set_blend_mode($renderer, SDL2::BlendMode::BLEND)
	renderer_flush($renderer)
	# TODO
	
	$shapes = []
    
    
    $shapes << Shapes::line_new(0, 1, WINDOW_WIDTH, 1)
    $shapes << Shapes::line_new(0, WINDOW_HEIGHT-1, WINDOW_WIDTH, WINDOW_HEIGHT-1)
    $shapes << Shapes::line_new(1, 1, 1, WINDOW_HEIGHT-1)
    $shapes << Shapes::line_new(WINDOW_WIDTH-1, 1, WINDOW_WIDTH-1, WINDOW_HEIGHT-1)
    
    10.times do |i|
		$shapes << Shapes::square_new(rand(WINDOW_WIDTH - 200), rand(WINDOW_HEIGHT - 200), 50)
    end
    $rays = []
    
	$spr_light_cast = renderer_texture_load($renderer, '/home/dslaveykov/Downloads/misc/light_cast.png')
	
	$buff_light_ray = renderer_target_texture_new($renderer, WINDOW_WIDTH, WINDOW_HEIGHT)
	$buff_light_tex = renderer_target_texture_new($renderer, WINDOW_WIDTH, WINDOW_HEIGHT)
end

def cast_rays_to_each_vertex()

	cps = []

	edges_count = 0
	if true
		mpos = Events::mouse_position()
		$shapes.each do |s|
			edges_count += s[:edges].length()
			s[:edges].each do |e|
				$rays << Rays::ray_cast3(mpos[:x], mpos[:y], e[:x1], e[:y1], Rays::CAST_ONE_RAY)
				$rays << Rays::ray_cast3(mpos[:x], mpos[:y], e[:x2], e[:y2], Rays::CAST_ONE_RAY)
			end
		end
		
		$rays.each_index do |i|
			r = $rays[i]
			minx = 0
			miny = 0
			mina = 0
			mint1 = Float::INFINITY
			$shapes.each do |s|
				edges = s[:edges]
				edges.each do |e|
					cp = Rays::ray_edge_contact_point(r, e)
					if !cp.nil?()						
						if cp[:t1] < mint1
							mint1 = cp[:t1]
							minx = cp[:x]
							miny = cp[:y]
							mina = Math::atan2(miny - r[:y1], minx - r[:x1])
						end
					end
				end
			end
			cps << {x: minx, y: miny, a: mina}
			#renderer_draw_circle($renderer, minx, miny, 5.0, COLOR_YELLOW)
			$rays[i][:x2] = minx
			$rays[i][:y2] = miny
			#renderer_draw_line($renderer, r[:x1], r[:y1], r[:x2], r[:y2], COLOR_WHITE)
		end
	end
	
	cps = Utils::bubble_sort(cps, lambda{|a,b|
		return b[:a] > a[:a]
	})
	
	triangles = Utils::points_to_triangles(mpos[:x], mpos[:y], cps)
	
	triangles.each do |t|
		shape = Shapes::triangle_new(
			t[:x1],t[:y1],
			t[:x2],t[:y2],
			t[:x3],t[:y3]
		)
		renderer_fill_shape($renderer, shape, COLOR_WHITE)
	end

end

def cast_three_rays_to_each_vertex()

	cps = []
	if true
		mpos = Events::mouse_position()
		#cp_circle = Shapes::circle_new(mpos[:x], mpos[:y], 5.0)
		#renderer_fill_shape($renderer, cp_circle, COLOR_YELLOW)
		
		# cast a ray to each vertex of each edge of each shape
		edges_count = 0
		all_edges = []
		cps = []
		$shapes.each do |s|
			s[:edges].each do |e|
				edges_count += 1
				all_edges << e
				2.times do |i|
					x2 = ((i == 0) ? e[:x1] : e[:x2])
					y2 = ((i == 0) ? e[:y1] : e[:y2])
					$rays << Rays::ray_cast3(mpos[:x], mpos[:y], x2, y2, Rays::CAST_THREE_RAYS, 1300.0)
					$rays.flatten!()
				end
			end
		end
		
		# get each contact point between every ray and every edge of each shape
		$rays.each_index do |i|
			r = $rays[i]
			x1 = r[:x1]
			y1 = r[:y1]
			# same rays minx and miny
			minx = 0
			miny = 0
			mina = 0
			mint1 = Float::INFINITY
			
			all_edges.each do |e|
				cp = Rays::ray_edge_contact_point(r, e)
				if !cp.nil?()
					if cp[:t1] < mint1
						mint1 = cp[:t1]
						minx = cp[:x]
						miny = cp[:y]
						mina = Math::atan2(miny - y1, minx - x1)
					end
				end
			end
			
			cps << {x: minx, y: miny, a: mina}
			#renderer_draw_circle($renderer, minx, miny, 5.0, COLOR_YELLOW)
			$rays[i] = {x1: x1, y1: y1, x2: minx, y2: miny}
			#renderer_draw_line($renderer, x1, y1, minx, miny, COLOR_WHITE)
		end
	end
	
	# uncomment for triangle filling fans
	cps = Utils::bubble_sort(cps, lambda{|a,b|
		return b[:a] > a[:a]
	})
	
	renderer_draw_texture2($renderer, $buff_light_tex)
	
	w = $spr_light_cast.w/20
	h = $spr_light_cast.h/20
	x = mpos[:x] - (w/2)
	y = mpos[:y] - (h/2)
	renderer_draw_texture($renderer, $spr_light_cast, x, y, w, h)
	
	# UNCOMMENT WHEN GETTING PIXELS FROM A TEXTURE IS POSSIBLE
	#renderer_set_target_texture($renderer, $buff_light_ray)
	#renderer_clear($renderer)
	
	triangles = Utils::points_to_triangles(mpos[:x], mpos[:y], cps)
	
	triangles.each do |t|
		shape = Shapes::triangle_new(
			t[:x1],t[:y1],
			t[:x2],t[:y2],
			t[:x3],t[:y3]
		)
		renderer_fill_shape($renderer, shape, change_color_alpha(COLOR_WHITE, 175))
	end
	
	# UNCOMMENT WHEN GETTING PIXELS FROM A TEXTURE IS POSSIBLE
	#renderer_set_target_texture($renderer, nil)
	
	#WINDOW_WIDTH.times do |x|
	#	WINDOW_HEIGHT.times do |y|
	#		
	#	end
	#end
	
end

def cast_rays_in_all_directions()

	if true
		mpos = Events::mouse_position()
		radius = 1300.0
		num_rays = 90
		$rays = Rays::ray_cast2(mpos[:x], mpos[:y], radius, num_rays)
		cps = []
		$rays.each_index do |i|
			r = $rays[i]
			minx = 0
			miny = 0
			mina = 0
			mint1 = Float::INFINITY
			$shapes.each do |s|
				edges = s[:edges]
				edges.each do |e|
					cp = Rays::ray_edge_contact_point(r, e)
					if !cp.nil?()						
						if cp[:t1] < mint1
							mint1 = cp[:t1]
							minx = cp[:x]
							miny = cp[:y]
							mina = Math::atan2(miny - r[:y1], minx - r[:x1])
						end
					end
				end
			end
			cps << {x: minx, y: miny, a: mina}
			renderer_draw_circle($renderer, minx, miny, 5.0, COLOR_YELLOW)
			$rays[i][:x2] = minx
			$rays[i][:y2] = miny
			renderer_draw_line($renderer, r[:x1], r[:y1], r[:x2], r[:y2], COLOR_WHITE)
		end
		
	end
end

def cast_rays_in_fov()
	# TODO
end
	
def process_input()
	Events::update_hid()
	$quit = Events::keyboard_key_pressed?("escape")
	
	$rays.clear()
	
	#cast_rays_in_all_directions()
	
	#cast_rays_to_each_vertex()
	
	cast_three_rays_to_each_vertex()
	
	#cast_rays_in_fov()
	
end
	
def render_scene()
	$shapes.each do |s|
		renderer_draw_shape($renderer, s, COLOR_WHITE)
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
		renderer_set_target_texture($renderer, nil)
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

