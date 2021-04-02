#!/usr/bin/env ruby

=begin
	Note: ALL METHODS DOES NOT AFFECT the arguments (vectors passed to the method),
	      but instead RETURN A NEW VECTOR that is the result of the operation/method
	      
	TODO: implemente unit tests for this methods
=end
module Vector

	def self.mag(v)
		x_2 = v[:x]*v[:x]
		y_2 = v[:y]*v[:y]
		return Math::sqrt(x_2 + y_2)
	end

	def self.dot(va, vb)
		return va[:x]*vb[:x] + va[:y]*vb[:y]
	end
	
	def self.normalize(v)
		_mag = self.mag(v)
		return {
			x: v[:x]/_mag,
			y: v[:y]/_mag
		}
	end
	
	def self.scale(v, s)
		return {
			x: v[:x]*s,
			y: v[:y]*s
		}
	end
	
	def self.negate(v)
		return self.scale(v, -1.0)
	end
	
	def self.add(va, vb)
		return {
			x: va[:x] + vb[:x],
			y: va[:y] + vb[:y]
		}
	end
	
	def self.sub(va, vb)
		return {
			x: va[:x] - vb[:x],
			y: va[:y] - vb[:y]
		}
	end
	
	def self.mul(va, vb)
		return {
			x: va[:x] * vb[:x],
			y: va[:y] * vb[:y]
		}
	end
	
	def self.div(va, vb)
		return {
			x: va[:x] / vb[:x],
			y: va[:y] / vb[:y]
		}
	end

end
