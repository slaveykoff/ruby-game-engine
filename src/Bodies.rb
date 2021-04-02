#!/usr/bin/env ruby

require_relative './Utils.rb'

module Bodies

	DYNAMIC = 0
	STATIC = 1
	
	STATIC_BODY_MASS = 1_000_000_000_000

	def self.body_new(px, py, vx, vy, max_vx, max_vy, mass, type, restitution)
		throw "Max vx should be >=0, but was #{max_vx}" if max_vx < 0
		throw "Max vy should be >=0, but was #{max_vy}" if max_vy < 0
		
		throw "Mass should be >= 0, but was #{mass}" if mass < 0
		
		throw "Type must be #{STATIC} or #{DYNAMIC}, but was #{type}" if type != STATIC && type != DYNAMIC
		
		throw "Restitution (e) must be >= 0.0 and <= 1.0, but was #{restitution}" if restitution < 0.0 || restitution > 1.0
		
		return {
			type: type,
			px: px,
			py: py,
			vx: vx,
			vy: vy,
			mvx: max_vx,
			mvy: max_vy,
			m: mass,
			e: restitution,
			fx: 0,
			fy: 0
		}
	end

	def self.body_dynamic_new(px, py, vx, vy, max_vx, max_vy, mass, restitution)
		return body_new(px, py, vx, vy, max_vx, max_vy, mass, DYNAMIC, restitution)
	end
	
	def self.body_static_new(px, py, restitution, friction)
		return body_new(px, py, 0, 0, 0, 0, STATIC_BODY_MASS, STATIC, restitution)
	end
	
	def self.body_delete(b)
		b = nil
		return b
	end
	
	def self.body_apply_force(b, fx, fy)
		return if body_static?(b)
		b[:fx] += fx
		b[:fy] += fy
	end
	
	def self.body_apply_impulse(b, ix, iy)
		return if body_static?(b)
		b[:vx] += ix
		b[:vy] += iy
		
		body_limit_velocity(b)
	end
	
	def self.body_clear_forces(b)
		b[:fx] = 0
		b[:fy] = 0
	end
	
	def self.body_static?(b)
		return b[:type] == STATIC
	end
	
	def self.body_dynamic?(b)
		return b[:type] == DYNAMIC
	end
	
	def self.body_limit_velocity(b)
		return if body_static?(b)
		# LIMIT VELOCITY
		sign_x = (((b[:vx]) <= 0) ? -1 : 1)
		sign_y = (((b[:vy]) <= 0) ? -1 : 1)
		if b[:mvx] >= 0
			b[:vx] = b[:mvx] * sign_x if b[:vx].abs() > b[:mvx]
		end
		if b[:mvy] >= 0
			b[:vy] = b[:mvy] * sign_y if b[:vy].abs() > b[:mvy]
		end
	end

end
