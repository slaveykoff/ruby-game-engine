#!/usr/bin/env ruby

require_relative './Utils.rb'


module Shapes

	POLY     = "poly"
	QUAD     = "quad"
	RECT     = "rect"
	SQUARE   = "square"
	LINE     = "line"
	TRIANGLE = "triangle"
	CIRCLE   = "circle"

	class PolyBuilder
		def initialize()
			@points = []
		end
		
		def delete()
			@points.clear()
			@points = nil
		end
		
		def add_point(x, y)
			@points << {
				x: x,
				y: y
			}
			return self
		end
		
		def build()
			poly = poly_new(@points.clone())
			@points.clear()
			return poly
		end
	end

	def self.poly_new(points)
		poly = {
			points: points,
			edges: nil,
			triangles: nil,
			filling_lines: nil,
			centroid: nil,
			name: POLY
		}
		
		poly[:edges] = _shape_to_edges(poly)
		poly[:triangles] = _shape_to_triangles(poly)
		poly[:filling_lines] = _shape_to_filling_lines(poly[:triangles])
		poly[:centroid] = _calculate_poly_centroid(points)
		
		return poly
	end

	def self.quad_new(x1, y1, x2, y2, x3, y3, x4, y4)
		points = []
		points << {
			x: x1,
			y: y1
		}
		points << {
			x: x2,
			y: y2
		}
		points << {
			x: x3,
			y: y3
		}
		points << {
			x: x4,
			y: y4
		}
		
		quad = poly_new(points)
		quad[:name] = QUAD
		
		return quad
	end

	def self.rect_new(x, y, w, h)
		x1 = x
		y1 = y
		
		x2 = x + w
		y2 = y
		
		x3 = x + w
		y3 = y + h
		
		x4 = x
		y4 = y + h
		
		rect = quad_new(x1, y1, x2, y2, x3, y3, x4, y4)
		rect[:name] = RECT
		
		return rect
	end

	def self.square_new(x, y, size)
		square = rect_new(x, y, size, size)
		square[:name] = SQUARE
		return square
	end

	def self.triangle_new(x1, y1, x2, y2, x3, y3)
		points = []
		points << {
			x: x1,
			y: y1
		}
		points << {
			x: x2,
			y: y2
		}
		points << {
			x: x3,
			y: y3
		}
		
		triangle = poly_new(points)
		triangle[:name] = TRIANGLE
		
		return triangle
	end

	def self.line_new(x1, y1, x2, y2)
		points = []
		points << {
			x: x1,
			y: y1
		}
		points << {
			x: x2,
			y: y2
		}
		
		line = poly_new(points)
		line[:name] = LINE
		
		line[:filling_lines] << {
			x1: line[:points][0][:x],
			y1: line[:points][0][:y],
			x2: line[:points][1][:x],
			y2: line[:points][1][:y]
		}
		
		return line
	end

	def self.circle_new(cx, cy, r, sectors = 32)
		points = []
		angle = 2 * Math::PI / sectors
		prev_i_sin = nil
		prev_i_cos = nil
		edges = []
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
		circle = poly_new(points)
		circle[:edges].clear()
		circle[:edges] = edges
		circle[:name] = CIRCLE
		
		# circle specific attributes
		circle[:radius] = r
		return circle
	end

	# Note: always assign the result of this method to the inital shape passed!
	def self.shape_delete(shape)
		return if shape.nil?()
		
		if !shape[:points].nil?()
			shape[:points].clear()
			shape[:points] = nil
		end
		
		
		if !shape[:edges].nil?()
			shape[:edges].clear()
			shape[:edges] = nil
		end
		
		
		if !shape[:triangles].nil?()
			shape[:triangles].clear()
			shape[:triangles] = nil
		end
		
		if !shape[:filling_lines].nil?()
			shape[:filling_lines].clear()
			shape[:filling_lines] = nil
		end
		
		shape[:centroid] = nil
		
		shape = nil
		
		return nil
	end

	def self.shape_copy(shape)
		cpy = poly_new(shape[:points].clone())
		cpy[:name] = shape[:name].clone()
		return shape
	end

	def self.shape?(shape, name)
		return shape[:name].eql?(name)
	end

	def self.shape_translate(shape, x, y)
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
		#shape[:edges].clear()
		#shape[:edges] = _shape_to_edges(shape)
		shape[:triangles].each do |t|
			t[:x1] += x
			t[:y1] += y
			t[:x2] += x
			t[:y2] += y
			t[:x3] += x
			t[:y3] += y
		end
		#shape[:triangles].clear()
		#shape[:triangles] = _shape_to_triangles(shape)
		
		shape[:filling_lines].each do |e|
			e[:x1] += x
			e[:y1] += y
			e[:x2] += x
			e[:y2] += y
		end
		#shape[:filling_lines] = []
		
		shape[:centroid][:x] += x
		shape[:centroid][:y] += y
	end

	def self.shape_rotate(shape, angle_deg)
		# TODO - Use Utils::rotate_polygon()		
		throw "Not implemented"
	end
	
	def self.contains_point?(shape, point)
		if shape?(shape, LINE)			
			buffer = 0.1
			
			d1 = Utils::distance(point[:x], point[:y], shape[:points][0][:x], shape[:points][0][:y])
			d2 = Utils::distance(point[:x], point[:y], shape[:points][1][:x], shape[:points][1][:y])
			
			line_len = Utils::distance(shape[:points][0][:x], shape[:points][0][:y], shape[:points][1][:x], shape[:points][1][:y])
			
			return ((d1 + d2 >= line_len - buffer) && (d1 + d2 <= line_len + buffer))
		elsif shape?(shape, CIRCLE)
			dx = point[:x] - shape[:centroid][:x]
			dy = point[:y] - shape[:centroid][:y]
			
			dist = Math::sqrt((dx*dx)+ (dy*dy))
			
			return dist <= shape[:radius]
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

	private 
	def self._shape_to_edges(shape)
		edges = []
		# only line has two points
		if shape[:points].size() == 2
			edges << {
				x1: shape[:points][0][:x],
				y1: shape[:points][0][:y],
				
				x2: shape[:points][1][:x],
				y2: shape[:points][1][:y]
			}		
			return edges
		end
		shape[:points].each_index do |i|
			x1 = shape[:points][i][:x]
			y1 = shape[:points][i][:y]
			
			i2 = i + 1
			if i2 >= shape[:points].size()
				i2 = 0
			end
			
			x2 = shape[:points][i2][:x]
			y2 = shape[:points][i2][:y]
			
			edges << {
				x1: x1,
				y1: y1,
				x2: x2,
				y2: y2
			}
		end
		
		return edges
	end

	def self._shape_to_triangles(shape)
		
		# only line has two points
		if shape[:points].size() == 2
			return []
		end
		triangles = []
		sorted_points = shape[:points].clone()
		
		shape[:points].each_index do |i|
			i += 1
			break if i+1 >= sorted_points.size()
			triangles << {
				x1: sorted_points[0][:x], y1: sorted_points[0][:y],
				x2: sorted_points[i][:x], y2: sorted_points[i][:y],
				x3: sorted_points[i+1][:x], y3: sorted_points[i+1][:y]
			}
		end
		
		return triangles
	end

	def self._shape_to_filling_lines(triangles)
		lines = []
		
		# only line has no triangles
		return lines if triangles.nil?() || triangles.size() == 0
		
		triangles.each do |t|
			
			x1 = t[:x1]
			y1 = t[:y1]
			
			x2 = t[:x2]
			y2 = t[:y2]
			
			x3 = t[:x3]
			y3 = t[:y3]
		
			# sort vertices
			sorted_points = []
			sorted_points << {
				x: x1,
				y: y1
			}
			sorted_points << {
				x: x2,
				y: y2
			}
			sorted_points << {
				x: x3,
				y: y3
			}
			# bubble sort (or something like that)
			#sorted_points.each_index do |index|
			#  (sorted_points.length - 1).downto( index ) do |i|
			#	sorted_points[i-1], sorted_points[i] = sorted_points[i], sorted_points[i-1] if sorted_points[i-1][:y] > sorted_points[i][:y]
			#  end
			#end
			
			sorted_points = Utils::bubble_sort(sorted_points, lambda{|a,b|
				return b[:y] > a[:y]
			})
			
			if sorted_points[1][:y] == sorted_points[2][:y]
				# fillBottomFlatTriangle
				invslope1 = (sorted_points[1][:x] - sorted_points[0][:x]).to_f() / (sorted_points[1][:y] - sorted_points[0][:y]).to_f()
				invslope2 = (sorted_points[2][:x] - sorted_points[0][:x]).to_f() / (sorted_points[2][:y] - sorted_points[0][:y]).to_f()
				curx1 = sorted_points[0][:x]
				curx2 = sorted_points[0][:x]
				
				scanline = sorted_points[0][:y]
				
				loop do
					break if scanline > sorted_points[1][:y]
					lines << {x1: curx1, y1: scanline, x2: curx2, y2: scanline}
					#renderer_draw_line(renderer, curx1, scanline, curx2, scanline, color)
					
					curx1 += invslope1
					curx2 += invslope2
					scanline += 1
				end
			elsif sorted_points[0][:y] == sorted_points[1][:y]
				# fillTopFlatTriangle
				invslope1 = (sorted_points[2][:x] - sorted_points[0][:x]).to_f() / (sorted_points[2][:y] - sorted_points[0][:y]).to_f()
				invslope2 = (sorted_points[2][:x] - sorted_points[1][:x]).to_f() / (sorted_points[2][:y] - sorted_points[1][:y]).to_f()
				curx1 = sorted_points[2][:x]
				curx2 = sorted_points[2][:x]
				scanline = sorted_points[2][:y]
				loop do
					break if scanline <= sorted_points[0][:y]
					lines << {x1: curx1, y1: scanline, x2: curx2, y2: scanline}
					
					curx1 -= invslope1
					curx2 -= invslope2
					scanline -= 1
				end
			else
				# fillBottomFlatTriangle, but with new point/vertex
				old_sorted_points = sorted_points.clone()
				# (int)(vt1.x + ((float)(vt2.y - vt1.y) / (float)(vt3.y - vt1.y)) * (vt3.x - vt1.x))
				a = sorted_points[0][:x].to_f() #vt1.x.to_f()
				b = sorted_points[1][:y].to_f() - sorted_points[0][:y].to_f() #(vt2.y - vt1.y).to_f()
				c = sorted_points[2][:y].to_f() - sorted_points[0][:y].to_f() # (vt3.y - vt1.y).to_f()
				d = sorted_points[2][:x].to_f() - sorted_points[0][:x].to_f() #(vt3.x - vt1.x).to_f()
				#puts a + (b / c) * d
				sorted_points[2] = {
					x: a + (b / c) * d,
					y: sorted_points[1][:y]
				}
				invslope1 = (sorted_points[1][:x] - sorted_points[0][:x]).to_f() / (sorted_points[1][:y] - sorted_points[0][:y]).to_f()
				invslope2 = (sorted_points[2][:x] - sorted_points[0][:x]).to_f() / (sorted_points[2][:y] - sorted_points[0][:y]).to_f()
				curx1 = sorted_points[0][:x]
				curx2 = sorted_points[0][:x]
				
				scanline = sorted_points[0][:y]
				
				loop do
					break if scanline > sorted_points[1][:y]
					lines << {x1: curx1, y1: scanline, x2: curx2, y2: scanline}
					
					curx1 += invslope1
					curx2 += invslope2
					scanline += 1
				end
				# fillTopFlatTriangle, but with (the already calculated) new point/vertex
				sorted_points.clear()
				sorted_points[0] = old_sorted_points[1]
				sorted_points[1] = {
					x: a + (b / c) * d,
					y: old_sorted_points[1][:y]
				}
				sorted_points[2] = old_sorted_points[2]
				invslope1 = (sorted_points[2][:x] - sorted_points[0][:x]).to_f() / (sorted_points[2][:y] - sorted_points[0][:y]).to_f()
				invslope2 = (sorted_points[2][:x] - sorted_points[1][:x]).to_f() / (sorted_points[2][:y] - sorted_points[1][:y]).to_f()
				curx1 = sorted_points[2][:x]
				curx2 = sorted_points[2][:x]
				scanline = sorted_points[2][:y]
				loop do
					break if scanline <= sorted_points[0][:y]
					lines << {x1: curx1, y1: scanline, x2: curx2, y2: scanline}
					
					curx1 -= invslope1
					curx2 -= invslope2
					scanline -= 1
				end
			end
		end
		
		return lines
	end

	# return {x, y}
	def self._calculate_poly_centroid(points)
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
