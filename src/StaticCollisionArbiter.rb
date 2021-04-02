#!/usr/bin/env ruby

require_relative './Utils.rb'
require_relative './CollisionShapes.rb'
require_relative './Bodies.rb'

module StaticCollisionArbiter

	# Note that this method does not change velocities
	# This means that if a force/impulse is constanctly being applied to the bodies
	# their velocities will grow up to max (if such limit is presented)
	# This can lead to tunneling of the bodies through one another!
	
	# Way this can be handled is to apply
	# 1. Friction to the bodies
	# 2. Elasticity and inverting of both velocities
	# 3. Linear (space/world) damping to the bodies' velocities
	# 4. Explicitly set their velocities to 0 (zero) after this method returns not nil for manifold
	def self.resolve(sa, ba, sb, bb)
	
		return nil if !CollisionShapes::collide?(sa, sb)
	
		# CIRCLE VS XYZ START
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_CIRCLE) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_CIRCLE)
			return circle_vs_circle(sa, ba, sb, bb)
		end
		
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_CIRCLE) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_CAPSULE)
			return circle_vs_capsule(sa, ba, sb, bb)
		end
		
		if CollisionShapes::collision_shape?(sb, CollisionShapes::CS_CIRCLE) && 
		   CollisionShapes::collision_shape?(sa, CollisionShapes::CS_CAPSULE)
			return circle_vs_capsule(sb, bb, sa, ba)
		end
		
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_CIRCLE) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_AABB)
			return circle_vs_aabb(sa, ba, sb, bb)
		end
		
		if CollisionShapes::collision_shape?(sb, CollisionShapes::CS_CIRCLE) && 
		   CollisionShapes::collision_shape?(sa, CollisionShapes::CS_AABB)
			return circle_vs_aabb(sb, bb, sa, ba)
		end

		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_CIRCLE) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_POLYGON)
			return circle_vs_polygon(sa, ba, sb, bb)
		end
		
		if CollisionShapes::collision_shape?(sb, CollisionShapes::CS_CIRCLE) && 
		   CollisionShapes::collision_shape?(sa, CollisionShapes::CS_POLYGON)
			return circle_vs_polygon(sb, bb, sa, ba)
		end
		# CIRCLE VS XYZ END
		# CAPSULE VS XYZ START
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_CAPSULE) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_CAPSULE)
			return capsule_vs_capsule(sa, ba, sb, bb)
		end
		
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_CAPSULE) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_AABB)
			return capsule_vs_aabb(sa, ba, sb, bb)
		end
		
		if CollisionShapes::collision_shape?(sb, CollisionShapes::CS_CAPSULE) && 
		   CollisionShapes::collision_shape?(sa, CollisionShapes::CS_AABB)
			return capsule_vs_aabb(sb, bb, sa, ba)
		end
		
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_CAPSULE) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_POLYGON)
			return capsule_vs_polygon(sa, ba, sb, bb)
		end
		
		if CollisionShapes::collision_shape?(sb, CollisionShapes::CS_CAPSULE) && 
		   CollisionShapes::collision_shape?(sa, CollisionShapes::CS_POLYGON)
			return capsule_vs_polygon(sb, bb, sa, ba)
		end
		# CAPSULE VS XYZ END
		# AABB VS XYZ START
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_AABB) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_AABB)
			return aabb_vs_aabb(sa, ba, sb, bb)
		end
		
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_AABB) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_POLYGON)
			return aabb_vs_polygon(sa, ba, sb, bb)
		end
		
		if CollisionShapes::collision_shape?(sb, CollisionShapes::CS_AABB) && 
		   CollisionShapes::collision_shape?(sa, CollisionShapes::CS_POLYGON)
			return aabb_vs_polygon(sb, bb, sa, ba)
		end
		# AABB VS XYZ END
		# POLYGON VS XYZ START
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_POLYGON) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_POLYGON)
			return polygon_vs_polygon(sa, ba, sb, bb)
		end
		# POLYGON VS XYZ END
		
		
		throw "Not implemented for '#{sa[:name]}' and '#{sb[:name]}' !"
	end
	
	def self.circle_vs_capsule(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = circle_vs_capsule_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.circle_vs_aabb(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = circle_vs_aabb_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.circle_vs_polygon(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = circle_vs_polygon_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.capsule_vs_capsule(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = capsule_vs_capsule_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.capsule_vs_aabb(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = capsule_vs_aabb_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.capsule_vs_polygon(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = capsule_vs_polygon_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.aabb_vs_aabb(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = aabb_vs_aabb_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.aabb_vs_polygon(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = aabb_vs_polygon_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.polygon_vs_polygon(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = polygon_vs_polygon_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.circle_vs_circle(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = circle_vs_circle_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	# MANIFOLD METHODS START
	def self.circle_vs_circle_collision_manifold(c1, c2)
		manifold = {
			normal: nil,
			penetration: 0
		}
	
		dx = (c1[:x] - c2[:x])*1.0
		dy = (c1[:y] - c2[:y])*1.0
	
		d = Math::sqrt((dx*dx) + (dy*dy))
		
		# no collision
		return nil if d > c1[:r] + c2[:r]
	
		x_2 = dx*dx
		y_2 = dy*dy
		l = Math::sqrt(x_2 + y_2)
	
		manifold[:normal] = {
			x: dx/l,
			y: dy/l
		}
		manifold[:penetration] = d - (c1[:r] + c2[:r])
	
		return manifold
	end
	
	# way too slow (maybe)
	def self.circle_vs_capsule_collision_manifold(ci, cap)
		line_x1 = (cap[:x2] - cap[:x1])*1.0
		line_y1 = (cap[:y2] - cap[:y1])*1.0
		
		line_x2 = (ci[:x] - cap[:x1])*1.0
		line_y2 = (ci[:y] - cap[:y1])*1.0
		
		edge_length = (line_x1*line_x1) + (line_y1*line_y1)
		
		# return if no collision
		return nil if edge_length == 0
		
		# Note: Possible division by zero if edge_length = 0
		# t = (0, (edge_length, (DOT PRODUCT OF VECTORS CIRCLE-TO-START_CAPSULE_CIRCLE AND VECTOR START_CAPSULE_CIRCLE-TO-END_CAPSULE_CIRCLE )).min).max()
		#t = [ 0, [ edge_length, ( (line_x1 * line_x2) + (line_y1 * line_y2) ) ].min() ].max() / edge_length
		
		dot_product = ( (line_x1 * line_x2) + (line_y1 * line_y2) )
		#p "dot_product is nil!" if dot_product.nil?()
		#p "edge_length is nil!" if edge_length.nil?()
		_min = ((edge_length < dot_product) ? edge_length : dot_product)
		_max = [ 0, _min ].max()
		
		t = _max / edge_length
		
		# calculate closest points (cpx and cpy)
		cpx = (cap[:x1] + (t * line_x1))*1.0
		cpy = (cap[:y1] + (t * line_y1))*1.0
		
		# calculate distance between circle's center and the closes point on the capsule's edge
		# Utils::distance(cpx, cpy, ci[:x], ci[:y])#
		d = Math::sqrt( (ci[:x] - cpx)*(ci[:x] - cpx) + ( (ci[:y] - cpy)*(ci[:y] - cpy) ) )
		
		if d <= (ci[:r] + cap[:r])
			fake_circle = CollisionShapes::collision_circle_new(cpx, cpy, cap[:r])
			return circle_vs_circle_collision_manifold(ci, fake_circle)
		else
			# no collision
			return nil
		end
	end
	
	def self.circle_vs_aabb_collision_manifold(sa, sb)
		
		manifold = {
			normal: nil,
			penetration: 0
		}
		
		# transform AABB to RECT
		sbx = sb[:x] - sb[:hw]
		sby = sb[:y] - sb[:hh]
		sbw = sb[:hw]*2
		sbh = sb[:hh]*2

		# find nearest point to the rectangle from the circle
		nx = [ sbx, [ 
				sbx + sbw, sa[:x]
			].min() 
		].max()
		ny = [ sby, [
				sby + sbh, sa[:y] 
			].min() 
		].max()
	
		circle_nearest_vec = {
			x: nx - sa[:x],
			y: ny - sa[:y]
		}
	
		circle_nearest_vec_length = Math::sqrt((circle_nearest_vec[:x]*circle_nearest_vec[:x]) + (circle_nearest_vec[:y]*circle_nearest_vec[:y]))
		
		return nil if circle_nearest_vec_length == 0
	
		# find the distance between the circle' center and this nearest point
		manifold[:penetration] = sa[:r] - circle_nearest_vec_length
	
		# normal_vector(circle_nearest_vec)
		manifold[:normal] = {
			x: circle_nearest_vec[:x] / (circle_nearest_vec_length*1.0),
			y: circle_nearest_vec[:y] / (circle_nearest_vec_length*1.0)
		}
	
		#sa[:x] -= manifold[:normal][:x]*(manifold[:penetration])
		#sa[:y] -= manifold[:normal][:y]*(manifold[:penetration])
		
		
		return manifold
		
	end
	
	def self.circle_vs_polygon_collision_manifold(ci, poly)
		# make capsules for each of the polygon's edges
		# perform circle vs each capsule
		
		edges = poly[:edges]
		radius = 1.0 # TODO play with it
		edges.each do |e|
			capsule = CollisionShapes::collision_capsule_new(
				e[:x1],
				e[:y1],
				e[:x2],
				e[:y2],
				radius
			)
			manifold = circle_vs_capsule_collision_manifold(ci, capsule)
			return manifold if !manifold.nil?()
		end
		# no collision
		return nil
	end
	
	def self.capsule_vs_capsule_collision_manifold(cap1, cap2)
		return _capsule_parts_vs_shape_manifold(cap1, cap2)
	end
	
	def self.capsule_vs_aabb_collision_manifold(cap, aabb)
		# transform AABB to capsules
		# fake RECT shape for AABB
		fake_rect_shape = {
			edges: []
		}
		fake_rect_shape[:edges] << {
			x1: aabb[:x] - aabb[:hw],
			y1: aabb[:y] - aabb[:hh],
			
			x2: aabb[:x] + aabb[:hw],
			y2: aabb[:y] - aabb[:hh]
		}
		fake_rect_shape[:edges] << {
			x1: aabb[:x] + aabb[:hw],
			y1: aabb[:y] - aabb[:hh],
			
			x2: aabb[:x] + aabb[:hw],
			y2: aabb[:y] + aabb[:hh]
		}
		fake_rect_shape[:edges] << {
			x1: aabb[:x] + aabb[:hw],
			y1: aabb[:y] + aabb[:hh],
			
			x2: aabb[:x] - aabb[:hw],
			y2: aabb[:y] + aabb[:hh]
		}
		fake_rect_shape[:edges] << {
			x1: aabb[:x] - aabb[:hw],
			y1: aabb[:y] + aabb[:hh],
			
			x2: aabb[:x] - aabb[:hw],
			y2: aabb[:y] - aabb[:hh]
		}
		
		aabb_capsules = CollisionShapes::shape_to_collision_shape(
			fake_rect_shape, CollisionShapes::CS_CAPSULE
		)
		aabb_capsules.each do |aabb_cap|
			manifold = capsule_vs_capsule_collision_manifold(cap, aabb_cap)
			return manifold if !manifold.nil?()
		end
		# no collision
		return nil
	end
	
	def self.capsule_vs_polygon_collision_manifold(cap, poly)
		# this one does not work for polygon
		#return _capsule_parts_vs_shape_manifold(cap, poly)
		throw "Not implemented!"
	end
	
	def self.aabb_vs_aabb_collision_manifold(aabb1, aabb2)
		
		return nil if !CollisionShapes::aabb_vs_aabb_collide?(aabb1, aabb2)
		
		max_1 = {
			x: aabb1[:x] + aabb1[:hw],
			y: aabb1[:y] + aabb1[:hh]
		}
		min_1 = {
			x: aabb1[:x] - aabb1[:hw],
			y: aabb1[:y] - aabb1[:hh]
		}
		
		max_2 = {
			x: aabb2[:x] + aabb2[:hw],
			y: aabb2[:y] + aabb2[:hh]
		}
		min_2 = {
			x: aabb2[:x] - aabb2[:hw],
			y: aabb2[:y] - aabb2[:hh]
		}
		
		faces = []
		faces << {
			x: -1,
			y: 0
		}
		faces << {
			x: 1,
			y: 0
		}
		faces << {
			x: 0,
			y: -1
		}
		faces << {
			x: 0,
			y: 1
		}
		
		distances = []
		
		distances << max_2[:x] - min_1[:x]
		distances << max_1[:x] - min_2[:x]
		distances << max_2[:y] - min_1[:y]
		distances << max_1[:y] - min_2[:y]
		
		best_axis = 0
		min_penetration = 1_000_000_000
		distances.each_index do |i|
			dst = distances[i]
			if dst < min_penetration
				min_penetration = dst
				best_axis = i
			end
		end
		
		manifold = {
			normal: faces[best_axis],
			penetration: min_penetration
		}
		
		return manifold
		
	end
	
	def self.aabb_vs_polygon_collision_manifold(aabb, poly)
		throw "Not implemented!"
	end
	
	def self.polygon_vs_polygon_collision_manifold(poly1, poly2)
		throw "Not implemented!"
	end
	
	# MANIFOLD METHODS END
	
private

	def self._capsule_parts_vs_shape_manifold(capsule, shape)
		#throw "Not implemented!"
		# get the first capsule (cap1)
		# break it to parts
		# starting from the first circle,
		# create circles along the middle line until end circle
		# the step can be either r which, depending on the r, can have big gaps
		# or make the step r/2, which will be perfect
		
		cap_parts = CollisionShapes::capsule_to_parts(capsule)
		# start circle
		cap_sc = cap_parts[:sc]
		# end circle
		cap_ec = cap_parts[:ec]
		dx = cap_ec[:x] - cap_sc[:x]
		dy = cap_ec[:y] - cap_sc[:y]
		
		stepx = (dx/(capsule[:r]*2.0))
		stepy = (dy/(capsule[:r]*2.0))
		
		cx = cap_sc[:x]
		cy = cap_sc[:y]
		loop do
			circle = CollisionShapes::collision_circle_new(cx, cy, capsule[:r])
			if CollisionShapes::circle_vs_circle_collide?(circle, cap_ec)
				# since we end up here, none of the previous check returned from this method
				# so here is the last place to check for collision
				# whatever returns the method below is the final manifold
				if CollisionShapes::collision_shape?(shape, CollisionShapes::CS_CIRCLE)
					return circle_vs_circle_collision_manifold(cap_ec, shape)
				end
				if CollisionShapes::collision_shape?(shape, CollisionShapes::CS_CAPSULE)
					return circle_vs_capsule_collision_manifold(cap_ec, shape)
				end
				if CollisionShapes::collision_shape?(shape, CollisionShapes::CS_AABB)
					return circle_vs_aabb_collision_manifold(cap_ec, shape)
				end
				if CollisionShapes::collision_shape?(shape, CollisionShapes::CS_POLYGON)
					return circle_vs_polygon_collision_manifold(cap_ec, shape)
				end
				
			end
			
			manifold = nil
			if CollisionShapes::collision_shape?(shape, CollisionShapes::CS_CIRCLE)
				manifold = circle_vs_circle_collision_manifold(circle, shape)
			end
			if CollisionShapes::collision_shape?(shape, CollisionShapes::CS_CAPSULE)
				manifold = circle_vs_capsule_collision_manifold(circle, shape)
			end
			if CollisionShapes::collision_shape?(shape, CollisionShapes::CS_AABB)
				manifold = circle_vs_aabb_collision_manifold(circle, shape)
			end
			if CollisionShapes::collision_shape?(shape, CollisionShapes::CS_POLYGON)
				manifold = circle_vs_polygon_collision_manifold(circle, shape)
			end
			
			return manifold if !manifold.nil?()
			cx += stepx
			cy += stepy
		end
		
	end

	def self._update_bodies(sa,ba,sb,bb,manifold)
		if Bodies::body_static?(ba)
			# b2 is dynamic
			CollisionShapes::collision_shape_translate(
				sb, 
				manifold[:penetration]*manifold[:normal][:x], 
				manifold[:penetration]*manifold[:normal][:y]
			)
			
			bb[:px] = sb[:centroid][:x]
			bb[:py] = sb[:centroid][:y]
			
			#bb[:vx] = 0
			#bb[:vy] = 0
		else
			if Bodies::body_static?(bb)
				CollisionShapes::collision_shape_translate(
					sa, 
					-manifold[:penetration]*manifold[:normal][:x], 
					-manifold[:penetration]*manifold[:normal][:y]
				)
				
				ba[:px] = sa[:centroid][:x]
				ba[:py] = sa[:centroid][:y]
			
				#ba[:vx] = 0
				#ba[:vy] = 0
			else
				# both are dynamic
				CollisionShapes::collision_shape_translate(
					sa, 
					-manifold[:penetration]*manifold[:normal][:x], 
					-manifold[:penetration]*manifold[:normal][:y]
				)
				
				ba[:px] = sa[:centroid][:x]
				ba[:py] = sa[:centroid][:y]
			
				#ba[:vx] = 0
				#ba[:vy] = 0
				
				CollisionShapes::collision_shape_translate(
					sb, 
					manifold[:penetration]*manifold[:normal][:x], 
					manifold[:penetration]*manifold[:normal][:y]
				)
			
				bb[:px] = sb[:centroid][:x]
				bb[:py] = sb[:centroid][:y]
			
				#bb[:vx] = 0
				#bb[:vy] = 0
			end
		end
	end

end
