#!/usr/bin/env ruby

require_relative './Utils.rb'
require_relative './Shapes.rb'


module CollisionShapes

	CS_AABB    = "aabb"
	CS_CIRCLE  = "circle"
	CS_CAPSULE = "capsule"
	CS_POLYGON = "polygon"

	def self.collision_aabb_new(x, y, hw, hh)
		return {
			x: x,
			y: y,
			hw: hw,
			hh: hh,
			centroid: {
				x: x,
				y: y
			},
			name: CS_AABB
		}
	end

	def self.collision_circle_new(x, y, r)
		return {
			x: x,
			y: y,
			r: r,
			centroid: {
				x: x,
				y: y
			},
			name: CS_CIRCLE
		}
	end

	def self.collision_capsule_new(x1, y1, x2, y2, r)
		capsule = {
			x1: x1,
			y1: y1,
			x2: x2,
			y2: y2,
			r: r,
			normal: Utils::normal_to_edge(x1, y1, x2, y2),
			name: CS_CAPSULE
		}
		mline = capsule_to_parts(capsule)[:ml]
		capsule[:centroid] = {
			x: mline[:x1] + ((mline[:x2]-mline[:x1])/2.0),
			y: mline[:y1] + ((mline[:y2]-mline[:y1])/2.0)
		}
		return capsule
	end

	def self.collision_polygon_new(points)
		polygon = {
			points: points.clone(),
			name: CS_POLYGON
		}
		polygon[:edges] = _polygon_to_edges(polygon)
		polygon[:centroid] = _calculate_polygon_centroid(points)
		return polygon
	end

	def self.collision_shape?(shape, name)
		return shape[:name].eql?(name)
	end

	def self.collision_shape_delete(shape)
		if shape[:name].eql?(CS_POLYGON)
			shape[:points].clear()
		end
		shape = nil
	end
	
	def self.collision_shape_to_collision_polygon(shape)
		return shape                         if shape[:name].eql?(CS_POLYGON)
		return _aabb_to_polygon(shape)       if shape[:name].eql?(CS_AABB)
		return _circle_to_polygon(shape, 32) if shape[:name].eql?(CS_CIRCLE)
		return _capsule_to_polygon(shape)    if shape[:name].eql?(CS_CAPSULE)
	end


	def self.collide?(sa, sb)

		return circle_vs_circle_collide?(sa,sb)      if collision_shape?(sa, CS_CIRCLE)  && collision_shape?(sb, CS_CIRCLE)
		
		return circle_vs_capsule_collide?(sa, sb)    if collision_shape?(sa, CS_CIRCLE)  && collision_shape?(sb, CS_CAPSULE)
		return circle_vs_capsule_collide?(sb, sa)    if collision_shape?(sb, CS_CIRCLE)  && collision_shape?(sa, CS_CAPSULE)
		
		return circle_vs_aabb_collide?(sa,sb)        if collision_shape?(sa, CS_CIRCLE)  && collision_shape?(sb, CS_AABB)
		return circle_vs_aabb_collide?(sb, sa)       if collision_shape?(sb, CS_CIRCLE)  && collision_shape?(sa, CS_AABB)
		
		return circle_vs_polygon_collide?(sa,sb)     if collision_shape?(sa, CS_CIRCLE)  && collision_shape?(sb, CS_POLYGON)
		return circle_vs_polygon_collide?(sb, sa)    if collision_shape?(sb, CS_CIRCLE)  && collision_shape?(sa, CS_POLYGON)
		
		return capsule_vs_capsule_collide?(sa,sb)    if collision_shape?(sa, CS_CAPSULE) && collision_shape?(sb, CS_CAPSULE)
		
		return capsule_vs_aabb_collide?(sa,sb)       if collision_shape?(sa, CS_CAPSULE) && collision_shape?(sb, CS_AABB)
		return capsule_vs_aabb_collide?(sb, sa)      if collision_shape?(sb, CS_CAPSULE) && collision_shape?(sa, CS_AABB)
		
		return capsule_vs_polygon_collide?(sa,sb)    if collision_shape?(sa, CS_CAPSULE) && collision_shape?(sb, CS_POLYGON)
		return capsule_vs_polygon_collide?(sb, sa)   if collision_shape?(sb, CS_CAPSULE) && collision_shape?(sa, CS_POLYGON)
		
		
		return aabb_vs_aabb_collide?(sa,sb)          if collision_shape?(sa, CS_AABB)    && collision_shape?(sb, CS_AABB)
		
		return aabb_vs_polygon_collide?(sa,sb)       if collision_shape?(sa, CS_AABB)    && collision_shape?(sb, CS_POLYGON)
		return aabb_vs_polygon_collide?(sb, sa)      if collision_shape?(sb, CS_AABB)    && collision_shape?(sa, CS_POLYGON)
		
		return polygon_vs_polygon_collide?(sa,sb)    if collision_shape?(sa, CS_POLYGON) && collision_shape?(sb, CS_POLYGON)
		
		throw "Collision between '#{sa[:name]}' and '#{sb[:name]}' is not supported. Supported once are: circle/capsule/aabb/polygon!"
		
	end

	# point = {x, y}
	def self.contains_point?(shape, point)
		if collision_shape?(shape, CS_CIRCLE)
			dx = point[:x] - shape[:x]
			dy = point[:y] - shape[:y]
			
			dist = Math::sqrt((dx*dx)+ (dy*dy))
			
			return dist <= shape[:r]
		elsif collision_shape?(shape, CS_CAPSULE)
			cap_parts = capsule_to_parts(shape)
			return true if contains_point?(cap_parts[:sc], point) || contains_point?(cap_parts[:ec], point)
			
			points = []
			poly = collision_polygon_new(points)
			return contains_point?(poly, point)
		else
			collision = false
			shape[:points].each_index do |i|
				j = i+1
				j = 0 if i+1 >= shape[:points].size()
		
				collision = !collision if (((shape[:points][i][:y] >= point[:y] && shape[:points][j][:y] < point[:y]) || (shape[:points][i][:y] < point[:y] && shape[:points][j][:y] >= point[:y])) && 
									(point[:x] < (shape[:points][j][:x]-shape[:points][i][:x])*(point[:y]-shape[:points][i][:y]) / (shape[:points][j][:y]-shape[:points][i][:y])+shape[:points][i][:x]))
			end
			
			return collision
		end
	end

	def self.collision_shape_translate(shape, x, y)
		if collision_shape?(shape, CS_CIRCLE)
			shape[:x] += x
			shape[:y] += y
		elsif collision_shape?(shape, CS_AABB)
			shape[:x] += x
			shape[:y] += y
		elsif collision_shape?(shape, CS_CAPSULE)
			shape[:x1] += x
			shape[:y1] += y
			shape[:x2] += x
			shape[:y2] += y
			shape[:normal] = Utils::normal_to_edge(shape[:x1], shape[:y1], shape[:x2], shape[:y2])
			# translate the capsule's parts HERE
			# if they ever appear in the collision_capsule_new() method
		elsif collision_shape?(shape, CS_POLYGON)
			shape[:points].each do |p|
				p[:x] += x
				p[:y] += y
			end
			shape[:edges].each do |e|
				e[:x1] += x
				e[:y1] += y
				
				e[:x2] += x
				e[:y2] += y
			end
		else
			throw "Translation of collision shape '#{shape[:name]}' is not supported. Supported once are: circle/capsule/aabb/polygon!"
		end
		shape[:centroid][:x] += x
		shape[:centroid][:y] += y
	end

	def self.circle_vs_circle_collide?(sa, sb)	
		# find the distance between the two center points (d)
		# sum the radii (rr)
		# if rr <= d -> no collision, else collision
		
		dx = (sa[:x]-sb[:x])*1.0
		dy = (sa[:y]-sb[:y])*1.0
		
		dd = (dx*dx) + (dy*dy)
		rr = sa[:r] + sb[:r]*1.0
		
		return dd.abs() <= (rr*rr)
	end

	def self.circle_vs_capsule_collide?(ci, cap)
		line_x1 = (cap[:x2] - cap[:x1])*1.0
		line_y1 = (cap[:y2] - cap[:y1])*1.0
		
		line_x2 = (ci[:x] - cap[:x1])*1.0
		line_y2 = (ci[:y] - cap[:y1])*1.0
		
		edge_length = (line_x1*line_x1) + (line_y1*line_y1)
		
		return false if edge_length == 0
		
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
		
		return d <= (ci[:r] + cap[:r])
	end

	def self.circle_vs_aabb_collide?(sa, sb)
		nx = [sb[:x]-(sb[:hw]),[sb[:x]+(sb[:hw]),sa[:x]].min()].max()
		ny = [sb[:y]-(sb[:hh]),[sb[:y]+(sb[:hh]),sa[:y]].min()].max()
		
		return Utils::distance(sa[:x], sa[:y], nx, ny) <= sa[:r]
	end

	def self.circle_vs_polygon_collide?(sa, sb)		
		radius = 4
		# TODO these capsules can be created when the polygon is created !!!
		sb[:edges].each do |e|
			capsule = collision_capsule_new(e[:x1], e[:y1], e[:x2], e[:y2], radius)
			return true if circle_vs_capsule_collide?(sa, capsule)
		end
		# check if the circle is inside the polygon
		return contains_point?(sb, {
			x: sa[:x],
			y: sa[:y]
		})
	end
	
	def self.capsule_vs_capsule_collide?(sa, sb)
		
		# capsule = 2 circles + 3 lines
		
		# compare each circle/line of sa to each circles/lines of sb
		# TODO: these capsule parts can be created when the capsule is created !!!
		sa_parts = capsule_to_parts(sa)
		sb_parts = capsule_to_parts(sb)
		
		return true if circle_vs_circle_collide?(sa_parts[:sc], sb_parts[:sc])		
		return true if circle_vs_circle_collide?(sa_parts[:ec], sb_parts[:sc])
		
		return true if circle_vs_circle_collide?(sb_parts[:sc], sa_parts[:sc])		
		return true if circle_vs_circle_collide?(sb_parts[:ec], sa_parts[:sc])
		
		# sca vs mlb
		if circle_vs_capsule_collide?(sa_parts[:sc], collision_capsule_new(
							sb_parts[:ml][:x1],sb_parts[:ml][:y1],
							sb_parts[:ml][:x2],sb_parts[:ml][:y2],
							1.0
							)
		)
			return true
		end
		
		# scb vs mla
		if circle_vs_capsule_collide?(sb_parts[:sc], collision_capsule_new(
							sa_parts[:ml][:x1],sa_parts[:ml][:y1],
							sa_parts[:ml][:x2],sa_parts[:ml][:y2],
							1.0
							)
		)
			return true
		end
		
		# sca vs llb
		if circle_vs_capsule_collide?(sa_parts[:sc], collision_capsule_new(
							sb_parts[:ll][:x1],sb_parts[:ll][:y1],
							sb_parts[:ll][:x2],sb_parts[:ll][:y2],
							1.0
							)
		)
			return true
		end
		
		# scb vs lla
		if circle_vs_capsule_collide?(sb_parts[:sc], collision_capsule_new(
							sa_parts[:ll][:x1],sa_parts[:ll][:y1],
							sa_parts[:ll][:x2],sa_parts[:ll][:y2],
							1.0
							)
		)
			return true
		end

		# sca vs rlb
		if circle_vs_capsule_collide?(sa_parts[:sc], collision_capsule_new(
							sb_parts[:rl][:x1],sb_parts[:rl][:y1],
							sb_parts[:rl][:x2],sb_parts[:rl][:y2],
							1.0
							)
		)
			return true
		end
		
		# scb vs rla
		if circle_vs_capsule_collide?(sb_parts[:sc], collision_capsule_new(
							sa_parts[:rl][:x1],sa_parts[:rl][:y1],
							sa_parts[:rl][:x2],sa_parts[:rl][:y2],
							1.0
							)
		)
			return true
		end

		# eca vs mlb
		if circle_vs_capsule_collide?(sa_parts[:ec], collision_capsule_new(
							sb_parts[:ml][:x1],sb_parts[:ml][:y1],
							sb_parts[:ml][:x2],sb_parts[:ml][:y2],
							1.0
							)
		)
			return true
		end
		
		# ecb vs mla
		if circle_vs_capsule_collide?(sb_parts[:ec], collision_capsule_new(
							sa_parts[:ml][:x1],sa_parts[:ml][:y1],
							sa_parts[:ml][:x2],sa_parts[:ml][:y2],
							1.0
							)
		)
			return true
		end
		
		# eca vs llb
		if circle_vs_capsule_collide?(sa_parts[:ec], collision_capsule_new(
							sb_parts[:ll][:x1],sb_parts[:ll][:y1],
							sb_parts[:ll][:x2],sb_parts[:ll][:y2],
							1.0
							)
		)
			return true
		end
		
		# ecb vs lla
		if circle_vs_capsule_collide?(sb_parts[:ec], collision_capsule_new(
							sa_parts[:ll][:x1],sa_parts[:ll][:y1],
							sa_parts[:ll][:x2],sa_parts[:ll][:y2],
							1.0
							)
		)
			return true
		end

		# eca vs rlb
		if circle_vs_capsule_collide?(sa_parts[:ec], collision_capsule_new(
							sb_parts[:rl][:x1],sb_parts[:rl][:y1],
							sb_parts[:rl][:x2],sb_parts[:rl][:y2],
							1.0
							)
		)
			return true
		end
		
		# ecb vs rla
		if circle_vs_capsule_collide?(sb_parts[:ec], collision_capsule_new(
							sa_parts[:rl][:x1],sa_parts[:rl][:y1],
							sa_parts[:rl][:x2],sa_parts[:rl][:y2],
							1.0
							)
		)
			return true
		end
		## lla vs llb
		return true if line_vs_line_collide?(sa_parts[:ll],sb_parts[:ll])
		## lla vs rlb
		return true if line_vs_line_collide?(sa_parts[:ll],sb_parts[:rl])
		## llb vs rla
		return true if line_vs_line_collide?(sb_parts[:ll],sa_parts[:rl])
		## rla vs rlb
		return true if line_vs_line_collide?(sa_parts[:rl],sb_parts[:rl])
		
		# TODO - Add the checks, listed below:
		## mla vs mlb can be left not implemented for now,
		## since this case will be applicable only if the capsule's radius is too big
		### mla vs mlb
		#### Something happens when checking if mla vs mlb collide and shows collision, when such is not
		#### suppost to happen !!!!
		#return true if line_vs_line_collide?(sa_parts[:ml],sb_parts[:ml])
		### mla vs llb
		return true if line_vs_line_collide?(sa_parts[:ml],sb_parts[:ll])
		### mla vs rlb
		return true if line_vs_line_collide?(sa_parts[:ml],sb_parts[:rl])
		### mlb vs lla
		return true if line_vs_line_collide?(sb_parts[:ml],sa_parts[:ll])
		### mlb vs rla
		return true if line_vs_line_collide?(sb_parts[:ml],sa_parts[:rl])
		
		
		# no collision?!?
		return false
		
		
	end
	
	def self.capsule_vs_polygon_collide?(sa, sb)
		radius = 4
		sb[:edges].each do |e|
			capsule = collision_capsule_new(e[:x1], e[:y1], e[:x2], e[:y2], radius)
			return true if capsule_vs_capsule_collide?(sa, capsule)
		end
		# check if capsule inside polygon
		return true if contains_point?(sb, {
			x: sa[:x1],
			y: sa[:y1]
		})
		# return this as last result
		return contains_point?(sb, {
			x: sa[:x2],
			y: sa[:y2]
		})
	end

	def self.capsule_vs_aabb_collide?(sa, sb)
		aabb_polygon = _aabb_to_polygon(sb)
		return capsule_vs_polygon_collide?(sa, aabb_polygon)
	end
	
	def self.aabb_vs_aabb_collide?(sa, sb)
		#  can redirects to polygon_vs_polygon but AABB vs AABB will be faster
		
		sax = sa[:x] - sa[:hw]
		say = sa[:y] - sa[:hh]
		saw = sa[:hw]*2
		sah = sa[:hh]*2
		
		sbx = sb[:x] - sb[:hw]
		sby = sb[:y] - sb[:hh]
		sbw = sb[:hw]*2
		sbh = sb[:hh]*2
		
		return (sax + saw >= sbx) && (sax <= sbx + sbw) && (say + sah >= sby) && (say <= sby + sbh)
		
		#if (r1x + r1w >= r2x &&    // r1 right edge past r2 left
		#	r1x <= r2x + r2w &&    // r1 left edge past r2 right
		#	r1y + r1h >= r2y &&    // r1 top edge past r2 bottom
		#	r1y <= r2y + r2h) {    // r1 bottom edge past r2 top
        #return true;
		#}
		#return false;
		
	end

	def self.aabb_vs_polygon_collide?(sa, sb)
		aabb_polygon = _aabb_to_polygon(sa)
		return polygon_vs_polygon_collide?(aabb_polygon, sb)
	end

	def self.polygon_vs_polygon_collide?(sa, sb)
		# TODO - not tested!
		sa[:edges].each do |e|
			capsule = collision_capsule_new(e[:x1], e[:y1], e[:x2], e[:y2], 4)
			return true if capsule_vs_polygon_collide?(capsule, sb)
		end
		sb[:edges].each do |e|
			capsule = collision_capsule_new(e[:x1], e[:y1], e[:x2], e[:y2], 4)
			return true if capsule_vs_polygon_collide?(capsule, sa)
		end
		return false
	end
	
	# wrap the shape around a particular collision_shape(s)
	def self.shape_to_collision_shape(shape, collision_shape_name)
		if collision_shape_name.eql?(CS_CIRCLE)
			# calculate the circle's radius which is the largest distance between the centroid and each of the vertices/points
			radius = 0
			shape[:points].each do |p|
				radius = [
					radius,
					Utils::distance(p[:x], p[:y], shape[:centroid][:x], shape[:centroid][:y])
				].max()
			end
			return collision_circle_new(shape[:centroid][:x], shape[:centroid][:y], radius)
		elsif collision_shape_name.eql?(CS_CAPSULE)
			edges = shape[:edges]
			capsules = []
			capsules_radius = 0.1
			# TODO: these capsules can be created when the polygon is created !!!
			edges.each do |e|
				capsules << collision_capsule_new(e[:x1], e[:y1], e[:x2], e[:y2], capsules_radius)
			end
			return capsules
		elsif collision_shape_name.eql?(CS_POLYGON)
			return collision_polygon_new(shape[:points])
		else
			throw "Not implemented for collision shape name '#{collision_shape_name}'"
		end
		# TODO
		# AABB
	end
	
	
	def self.capsule_to_parts(cap)
		# Note: (Optimization) all this can be saved when the capsule is created!
		scir = collision_circle_new(cap[:x1], cap[:y1], cap[:r])
		ecir = collision_circle_new(cap[:x2], cap[:y2], cap[:r])
		mline = {
			x1: cap[:x1],
			y1: cap[:y1],
			x2: cap[:x2],
			y2: cap[:y2]
		}
		n = cap[:normal]
		lline = {
			x1: cap[:x1] + (cap[:r]*n[:x]),
			y1: cap[:y1] + (cap[:r]*n[:y]),
			x2: cap[:x2] + (cap[:r]*n[:x]),
			y2: cap[:y2] + (cap[:r]*n[:y])
		}
		rline = {
			x1: cap[:x1] - (cap[:r]*n[:x]),
			y1: cap[:y1] - (cap[:r]*n[:y]),
			x2: cap[:x2] - (cap[:r]*n[:x]),
			y2: cap[:y2] - (cap[:r]*n[:y])
		}
		# TODO - CREATE QUAD
		q = {
			x1: lline[:x1],
			y1: lline[:y1],
			
			x2: rline[:x1],
			y2: rline[:y1],
			
			x3: lline[:x2],
			y3: lline[:y2],
			
			x4: rline[:x2],
			y4: rline[:y2],
			
		}
		return {
			sc: scir,
			ec: ecir,
			ml: mline,
			ll: lline,
			rl: rline,
			q: q
		}
	end
	
	def self.line_vs_line_collide?(l1, l2)	
		x1 = l1[:x1]
		y1 = l1[:y1]
		x2 = l1[:x2]
		y2 = l1[:y2]
		
		x3 = l2[:x1]
		y3 = l2[:y1]
		x4 = l2[:x2]
		y4 = l2[:y2]
		
		return false if ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)) == 0
		
		
		a = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
		b = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))
		
		#float intersectionX = x1 + (uA * (x2-x1));
		#float intersectionY = y1 + (uA * (y2-y1));
		
		return a >= 0 && a <= 1 && b >= 0 && b <= 1
	end
	
	
### PRIVATE METHODS ###
	
	def self._polygon_to_edges(polygon)
		edges = []
		polygon[:points].each_index do |i|
			x1 = polygon[:points][i][:x]
			y1 = polygon[:points][i][:y]
			
			if i + 1 >= polygon[:points].size()
				i = 0
			else
				i += 1
			end
			
			x2 = polygon[:points][i][:x]
			y2 = polygon[:points][i][:y]
			
			edges << {
				x1: x1,
				y1: y1,
				x2: x2,
				y2: y2
			}
		end
		return edges
	end
	
	def self._circle_to_polygon(circle, sectors=32)
		points = []
		angle = 2 * Math::PI / sectors
		prev_i_sin = nil
		prev_i_cos = nil
		edges = []
		cx = circle[:x]
		cy = circle[:y]
		r = circle[:r]
		Utils::for(0, sectors, Utils::<(), 1, lambda{|i|
			cos_i_a = Math::cos(i * angle)
			sin_i_a = Math::sin(i * angle)
				
			if prev_i_cos.nil?()
				prev_i_cos = Math::cos((i - 1) * angle)
			end
			
			if prev_i_sin.nil?()
				prev_i_sin = Math::sin((i - 1) * angle)
			end	
		
			x1 = cx + r * cos_i_a
			y1 = cy + r * sin_i_a
			points << {
				x: x1,
				y: y1
			}
			x2 = cx + r * prev_i_cos
			y2 = cy + r * prev_i_sin
			points << {
				x: x2,
				y: y2
			}
			edges << {
				x1: x1,
				y1: y1,
				x2: x2,
				y2: y2
			}
			prev_i_sin = sin_i_a
			prev_i_cos = cos_i_a
		})
		polygon = collision_polygon_new(points)
		polygon[:edges].clear()
		polygon[:edges] = edges
		return polygon
	end
	
	def self._capsule_to_polygon(capsule)
		# TODO - NOT TESTED
		# disassemble the capsule to parts
		# get start circle -> transform to polygon -> get only the 1st half of the points
		# get end circle -> transform to polygon -> get only the 2nd half of the points
		# get the quad between the circles -> transform to polygon -> get all of the points
		# combine the points -> create new polygon
		# return this polygon
		capsule_parts = capsule_to_parts(capsule)
		
		start_circle = capsule_parts[:sc]
		start_circle_points = _circle_to_polygon(start_circle)[:points][0.._circle_to_polygon(start_circle)[:points].length/2] # or length/2 + 1
		end_circle = capsule_parts[:ec]
		end_circle_points = _circle_to_polygon(end_circle)[:points][0.._circle_to_polygon(end_circle)[:points].length/2] # or length/2 + 1
		quad_points = capsule_parts[:q]
		final_points = []
		final_points << start_circle_points << end_circle_points << quad_points
		# since we've inserted 3 arrays, now we want to expand them and get a single array with all of the 3 initial arrays' elements
		final_points.flatten!()		
		return collision_polygon_new(final_points)
	end
	
	def self._aabb_to_polygon(aabb)
		# TODO - this can also be saved once the AABB is created !!!
		points = []
		points << {
			x: aabb[:x] - aabb[:hw],
			y: aabb[:y] - aabb[:hh]
		}
		points << {
			x: aabb[:x] + aabb[:hw],
			y: aabb[:y] - aabb[:hh]
		}
		points << {
			x: aabb[:x] + aabb[:hw],
			y: aabb[:y] + aabb[:hh]
		}
		points << {
			x: aabb[:x] - aabb[:hw],
			y: aabb[:y] + aabb[:hh]
		}
		return collision_polygon_new(points)
	end

	
	
	# return {x, y}
	def self._calculate_polygon_centroid(points)
		# for line
		if points.size() == 2
			return {
				x: points[0][:x] + (points[1][:x] - points[0][:x]),
				y: points[0][:y] + (points[1][:y] - points[0][:y])
			}
		end	
		cx = 0
		cy = 0
		det = 0
		tempDet = 0
		j = 0
		nVertices = points.size()
		Utils::for(0, nVertices, Utils::<(), 1, lambda{|i|
			if i + 1 == nVertices
				j = 0
			else
				j = i + 1
			end
			# compute the determinant
			tempDet = points[i][:x] * points[j][:y] - points[j][:x] * points[i][:y]
			tempDet *= 1.0
			det += tempDet
			cx += (points[i][:x] + points[j][:x])*tempDet
			cy += (points[i][:y] + points[j][:y])*tempDet
		})
		det *= 1.0
		# divide by the total mass of the polygon
		cx /= 3*det
		cy /= 3*det
		return {
			x: cx,
			y: cy
		}
	end

end

