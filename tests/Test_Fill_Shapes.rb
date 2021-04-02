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


def fill_shapes()
	
	title = 'Renderer2D - Fill shapes - FPS:'
	
	w = window_new(title, 1152, 768, false)
	r = renderer_new(w, ACCELERATION_ON, VSYNC_OFF)

	# shape, color, filled (true|false)
	shapes_data = []
	
	# line
	shapes_data << {
		shape: Shapes::line_new(0,0,100,100),
		color: COLOR_WHITE,
		filled: true
	}
	
	# triangle
	shapes_data << {
		shape: Shapes::triangle_new(150,200, 350,200, 250,300),
		color: COLOR_RED,
		filled: true
	}
	
	# square
	shapes_data << {
		shape: Shapes::square_new(350, 50, 100),
		color: COLOR_GREEN,
		filled: true
	}
	
	# rect
	shapes_data << {
		shape: Shapes::rect_new(400, 250, 100, 50),
		color: COLOR_BLUE,
		filled: true
	}
	
	# quad
	shapes_data << {
		shape: Shapes::quad_new(
			500, 100,
			600, 100,
			550, 200,
			450, 200
			
		),
		color: COLOR_WHITE,
		filled: true
	}
	
	# poly
	points = []
	
	points << {x: 700, y: 100}
	points << {x: 800, y: 100}
	points << {x: 900, y: 300}
	points << {x: 800, y: 400}
	points << {x: 700, y: 400}
	points << {x: 600, y: 300}
	shapes_data << {
		shape: Shapes::poly_new(points),
		color: COLOR_RED,
		filled: true
	}

	window_show(w)

	frame_counter = Utils::frame_counter_new()
	loop do
		event = Events::update_hid()
		break if Events::keyboard_key_pressed?("escape")
		renderer_clear(r)
		shapes_data.each do |s|
			dy = 0.25
			dy = -768*1.5 if s[:shape][:centroid][:y] >= 768*1.25
			
			dx = 0.25
			dx = -1152*1.25 if s[:shape][:centroid][:x] >= 1152*1.25
			
			Shapes::shape_translate(s[:shape], dx, dy)
			if s[:filled]
				renderer_fill_shape(r, s[:shape], s[:color])
			else
				renderer_draw_shape(r, s[:shape], s[:color])
			end
		end
		renderer_flush(r)
		fps = Utils::update_frame_counter(frame_counter)
		if !fps.nil?()
			w[:impl].title = "#{title} #{fps}"
		end
	end

	shapes_data.each do |sd|
		Shapes::shape_delete(sd[:shape])
	end

	shapes_data.clear()
	shapes_data = nil

	window_hide(w)
	renderer_delete(r)
	window_delete(w)
end


def main()
	fill_shapes()
end

main()
