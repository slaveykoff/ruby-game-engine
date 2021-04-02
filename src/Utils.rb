#!/usr/bin/env ruby

module Utils

	FOR_CONDITION_EQUAL = 0
	FOR_CONDITION_NOT_EQUAL = 1
	FOR_CONDITION_LESS_THAN = 2
	FOR_CONDITION_LESS_THAN_OR_EQUAL = 3
	FOR_CONDITION_GREATHER_THAN = 4
	FOR_CONDITION_GREATHER_THAN_OR_EQUAL = 5
	
	$frame_counter_idx = 0
	$frame_counters = []
	
	def self.<()
		return FOR_CONDITION_LESS_THAN
	end
	
	def self.<=()
		return FOR_CONDITION_LESS_THAN_OR_EQUAL
	end
	
	def self.>()
		return FOR_CONDITION_GREATHER_THAN
	end
	
	def self.>=()
		return FOR_CONDITION_GREATHER_THAN_OR_EQUAL
	end
	
	def self.==()
		return FOR_CONDITION_EQUAL
	end
	
	def self.!=()
		return FOR_CONDITION_NOT_EQUAL
	end
	
	def self.for(start_val, end_val, condition, increment, body)
		tmp_val = start_val
		loop do
			if condition == FOR_CONDITION_EQUAL
				break if tmp_val != end_val
			elsif condition == FOR_CONDITION_LESS_THAN
				break if tmp_val >= end_val
			elsif condition == FOR_CONDITION_LESS_THAN_OR_EQUAL
				break if tmp_val > end_val
			elsif condition == FOR_CONDITION_GREATHER_THAN
				break if tmp_val <= end_val
			elsif condition == FOR_CONDITION_GREATHER_THAN_OR_EQUAL
				break if tmp_val < end_val
			elsif condition == FOR_CONDITION_NOT_EQUAL
				break if tmp_val == end_val
			else
				throw "Condition #{condition} NOT Supported!"
			end
			body.call(tmp_val) if !body.nil?()
			tmp_val += increment
		end
	end
	
	def self.deg_to_rad(a)
		a = a % 360
		# Degree x π/180 = Radian
		return a * Math::PI/180.0
	end
	
	def self.rad_to_deg(a)
		# Radians  × 180/π = Degrees
		return (a * 180.0/Math::PI) % 360
	end
	
	# check if two object are equal
	# a,b can be: numbers, objects, arrays, etc
	# the lambda returns true if equal and false if not
	def self.eql?(a, b, lambda)
		return lambda.call(a,b)
	end
	
	# the lambda must return true if b > a
	def self.bubble_sort(array, lambda)
		array.each_index do |i1|
			array.each_index do |i2|
				swap = lambda.call(array[i1], array[i2])
				if swap
					tmp = array[i1]
					array[i1] = array[i2]
					array[i2] = tmp
				end
			end
		end
		return array
	end
	
	def self.clone_array(array, copy_creation_lambda)
		cloned_array = []
		array.each do |a|
			cloned_array << copy_creation_lambda.call(a)
		end
		return cloned_array
	end
	
	# transform something like [0,1,1,3,3,2,2,2]
	# to [0,1,3,2]
	# Note: better performance if the array is sorted first!
	def self.unique(array, lambda)
		return array if array.length() <= 1
		unq_array = []
		array.each_index do |i|
			a = array[i]
			is_a_unique = true
			array.each_index do |j|
				next if i == j
				b = array[j]
				eql = Utils.eql?(a, b, lambda)
				is_a_unique = false if eql
			end
			#puts "#{a} is UNIQUE? #{is_a_unique}"
			unq_array << a if is_a_unique
			unq_array << a if !unq_array.include?(a)
		end
		return unq_array
	end
	
	def self.frame_counter_new()
		idx = $frame_counter_idx
		start_time = Time.now().to_f()
		$frame_counters[$frame_counter_idx] = {
			start_time: start_time,
			interval: 1.0,
			end_time: start_time + 1.0,
			frames: 0,
			ticks: 0,
			avg_frames: 0,
			total_frames: 0,
			min_frames: 10000000000
		}
		$frame_counter_idx += 1
		return idx
		
	end
	
	def self.update_frame_counter(idx)
		counter = $frame_counters[idx]
		return if counter.nil?()
		curr_time = Time.now().to_f()
		if curr_time >= counter[:end_time]
			counter[:ticks] += 1
			frames = counter[:frames]
			counter[:min_frames] = [counter[:min_frames], frames].min()
			counter[:total_frames] += frames
			counter[:avg_frames] = (counter[:total_frames]/counter[:ticks])
			counter[:frames] = 0
			counter[:start_time] = curr_time
			counter[:end_time] = counter[:start_time] + counter[:interval]
			return {
				frames: frames,
				avg_frames: counter[:avg_frames],
				min_frames: counter[:min_frames],
				ticks: counter[:ticks]
			}
		else
			counter[:frames] += 1
			return nil
		end
	end
	
	def self.translate_point(px, py, x, y)
		return {
			x: px + x,
			y: py + y
		}
	end
	
	# angle in degrees
	# opx - origin point x
	# opy - origin point y
	def self.rotate_point(px, py, angle, opx, opy)
		angle_rad = deg_to_rad(angle)
		#p'x = cos(theta) * (px-ox) - sin(theta) * (py-oy) + ox
		#p'y = sin(theta) * (px-ox) + cos(theta) * (py-oy) + oy
		
		cos_a = Math::cos(angle_rad)
		sin_a = Math::sin(angle_rad)
		
		dx = px - opx
		dy = py - opy
		
		fx = cos_a * dx - sin_a * dy + opx
		fy = sin_a * dx + cos_a * dy + opy
		
		return {
			x: fx,
			y: fy
		}
	end
	
	# points - array of {x, y}
	def self.translate_polygon(points, x, y)
		# TODO - NOT TESTED!
		points.each do |p|
			_p = translate_point(p[:x], p[:y], x, y)
			p[:x] = _p[:x]
			p[:y] = _p[:y]
		end
		return points
	end
	
	# angle in degrees
	def self.rotate_polygon(points, ox, oy, angle)
		# TODO - NOT TESTED!
		points.each do |p|
			_p = rotate_point(p[:x], p[:y], angle, ox, oy)
			p[:x] = _p[:x]
			p[:y] = _p[:y]
		end
		return points
	end
	
	def self.distance(x1, y1, x2, y2)
		return Math::sqrt( (x2 - x1)*(x2 - x1) + ( (y2 - y1)*(y2 - y1) ) )
	end
	
	def self.line_vs_line_contact_point(x1,y1, x2,y2, x3,y3, x4,y4)
		# this code is direct copy of the code in CollisionShapes::_line_vs_line_collide()
		cp = nil

		del_var = ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1))

		return nil if del_var == 0
		
		a = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / del_var
		b = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / del_var

		if a >= 0 && a <= 1 && b >= 0 && b <= 1
			cp = {
				x: x1 + (a * (x2-x1)),
				y: y1 + (a * (y2-y1)),
				t1: a
			}
		end
		return cp
	end
	
	# create triangle by using px,py + 2 consecutive points
	def self.points_to_triangles(px, py, points)
		triangles = []
		points.each_index do |i|
			p1 = points[i]
			p2 = points[i+1]
			break if p2.nil?()
			triangles << {
				x1: px,
				y1: py,
				
				x2: p1[:x],
				y2: p1[:y],
				
				x3: p2[:x],
				y3: p2[:y]
			}
		end
		triangles << {
			x1: px,
			y1: py,
			
			x2: points[-1][:x],
			y2: points[-1][:y],
			
			x3: points[0][:x],
			y3: points[0][:y]
		}
		return triangles
	end
	
	# or to line/segment
	def self.normal_to_edge(x1, y1, x2, y2)
		v = {
			x: -(y2 - y1),
			y: x2 - x1
		}
		l = Math::sqrt( (v[:x]*v[:x]) + (v[:y]*v[:y]) )
		
		v[:x] /= l
		v[:y] /= l
		
		return v
	end
	
	class Timer
		def initialize(interval, callback)
			@interval = interval
			@callback = callback
			@duration = 0
		end
		
		def start()
			@start_time = Time.now().to_f()
			@tmp_start_time = @start_time
			@duration = 0
		end
		
		def update()
			curr_time = Time.now().to_f()
			@duration = curr_time - @tmp_start_time
			if curr_time >= @tmp_start_time + @interval
				@tmp_start_time = curr_time
				@callback.call() if !@callback.nil?()
			end
		end
		
		def stop()
			@end_time = Time.now().to_f()
			@duration = @end_time - @start_time
		end
		
		# returns the duration between two consecutive updates if timer is not stopped/ is runnuing
		# or
		# the duration for the entire time between Timer.start() and Timer.stop() if the timer is stopped 
		def duration()
			return @duration
		end
	end
	
	
	class ArrayBuilder
		def initialize()
			@a = []
		end
		
		def add(e)
			@a << e
			return self
		end
		
		def build()			
			return @a
		end
	end
	
	
	
	class Queue
		def initialize()
			@elements = []
			@idx = 0
		end
		
		def enqueue(a)
			@elements << a
			@idx += 1
		end
		
		def take()
			a = @elements[@idx-1]
			@elements.delete(@idx-1)
			@idx -= 1
			@idx = 0 if @idx < 0
			return a
		end
		
		def peek()
			return @elements[@idx-1]
		end
		
		def size()
			return @idx
		end
		
		def clear()
			@idx = 0
			@elements.clear()
		end
		
		def empty?()
			return @elements.empty?()
		end
		
		def to_s()
			string = ""
			string << "Elements: ["
			@elements.each do |e|
				string << e.to_s() << ","
			end
			string << "], idx: #{@idx}"
			return string
		end
	
	end
	
	class Stack
		
		def initialize(size)
			@elements = []
			@orig_size = size
			@size_left = size
			@idx = 0
		end
		
		def push(a)
			throw "StackOverflow!" if @size_left == 0
			@elements << a
			@size_left -= 1
		end
		
		def peek()
			return @elements[0]
		end
		
		def pop()
			return @elements.pop()
		end
		
		def size()
			return @orig_size
		end
		
		def clear()
			@size_left = @orig_size
			@elements.clear()
		end
		
		def empty?()
			return @elements.empty?()
		end
		
		def to_s()
			string = ""
			string << "Elements: ["
			@elements.each do |e|
				string << e.to_s() << ","
			end
			# this is the original size, not the current one!
			string << "], size: #{@orig_size}"
			return string
		end
	end
	
end
