#/usr/bin/env ruby

require_relative './Utils.rb'

module Rays

	CAST_ONE_RAY    = 0
	CAST_THREE_RAYS = 1
	
	
	# angle in degrees
	def self.ray_cast(x, y, ray_radius, angle)
		ex = x + ray_radius*Math::sin(Utils::deg_to_rad(angle))
		ey = y + ray_radius*Math::cos(Utils::deg_to_rad(angle))
		return {
			x1: x, 
			y1: y, 
			x2: ex, 
			y2: ey
		}
	end
	
	def self.ray_cast2(x, y, ray_radius, ray_count)
		rays = []
		angle_step = 360.0 / ray_count
		ray_count.times do |a|
			ray = ray_cast(x, y, ray_radius, a * angle_step)
			rays << ray
		end
		return rays
	end
	
	def self.ray_cast3(x1, y1, x2, y2, cast_type, ray_radius = 1300.0)
		if cast_type == CAST_ONE_RAY
			return {
				x1: x1, 
				y1: y1, 
				x2: x2, 
				y2: y2
			}
		elsif cast_type == CAST_THREE_RAYS
			rays = []
			rdx = x2 - x1
			rdy = y2 - y1
			base_ang = Math::atan2(rdy, rdx)
			3.times do |j|
				ang = base_ang - 0.0001 if j == 0
				ang = base_ang          if j == 1
				ang = base_ang + 0.0001 if j == 2
					
				rdx = ray_radius * Math::cos(ang)
				rdy = ray_radius * Math::sin(ang)
					
				rays << {x1: x1, y1: y1, x2: x1 + rdx, y2: y1 + rdy}
			end
			return rays
		else
			throw "Unsupported cast_type! (#{cast_type})"
		end
	end
	
	def self.ray_edge_contact_point(r, e)
		cp = {}
		x1 = r[:x1]
		y1 = r[:y1]
					
		x2 = r[:x2]
		y2 = r[:y2]
					
		x3 = e[:x1]
		y3 = e[:y1]
					
		x4 = e[:x2]
		y4 = e[:y2]
		cp = Utils::line_vs_line_contact_point(x1,y1,x2,y2,x3,y3,x4,y4)
		return cp
	end
	
	def self.ray_edges_contact_points(r, edges)
		cps = {
			all_points: [],
			nearest_point_idx: 0,
			furthest_point_idx: 0
		}
		mint1 = 1_000_000_000
		maxt1 = -1_000_000_000
		cp_idx = 0
		edges.each do |e|
			cp = ray_edge_contact_point(r, e)
			next if cp.nil?()
			cps[:all_points] << cp
			if mint1 > cp[:t1]
				mint1 = cp[:t1]
				cps[:nearest_point_idx] = cp_idx
			end
			if maxt1 < cp[:t1]
				maxt1 = cp[:t1]
				cps[:furthest_point_idx] = cp_idx
			end
			cp_idx += 1
		end
		return cps
	end
end
