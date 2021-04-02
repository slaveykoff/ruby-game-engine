#!/usr/bin/env ruby

require_relative './Utils.rb'
require_relative './CollisionShapes.rb'
require_relative './Bodies.rb'
require_relative './Vector.rb'


module DynamicCollisionArbiter

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
		# TODO add CIRCLE VS POLYGON
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
		# TODO add CAPSULE VS POLYGON
		# CAPSULE VS XYZ END
		# AABB VS XYZ START
		if CollisionShapes::collision_shape?(sa, CollisionShapes::CS_AABB) && 
		   CollisionShapes::collision_shape?(sb, CollisionShapes::CS_AABB)
			return aabb_vs_aabb(sa, ba, sb, bb)
		end
		# AABB VS XYZ END
		# TODO add AABB VS POLYGON
		# POLYGON VS XYZ START
		# TODO add POLYGON VS POLYGON
		# POLYGON VS XYZ END
		
		throw "Not implemented for '#{sa[:name]}' and '#{sb[:name]}' !"
	end
	
	def self.circle_vs_circle(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = StaticCollisionArbiter::circle_vs_circle_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.circle_vs_capsule(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = StaticCollisionArbiter::circle_vs_capsule_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.circle_vs_aabb(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = StaticCollisionArbiter::circle_vs_aabb_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.capsule_vs_capsule(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = StaticCollisionArbiter::capsule_vs_capsule_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.capsule_vs_aabb(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = StaticCollisionArbiter::capsule_vs_aabb_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
	def self.aabb_vs_aabb(sa, ba, sb, bb)
		return nil if Bodies::body_static?(ba) && Bodies::body_static?(bb)
		manifold = StaticCollisionArbiter::aabb_vs_aabb_collision_manifold(sa, sb)
		return nil if manifold.nil?()
		_update_bodies(sa, ba, sb, bb, manifold)
		return manifold
	end
	
private


	def self._update_bodies(sa,ba,sb,bb,manifold)
		# NOTE: This is Impulse-Based dynamic collision resolution
		# because we manipulate the velocities directly, rather than the acceleration (the forces) directly
		# The later is called Force-Based dynamic collision resolution
		# and is usefull when dealing with constraints like gears, bridges, etc
			
		bapx = ba[:px]
		bapy = ba[:py]
			
		bavx = ba[:vx]
		bavy = ba[:vy]
			
		bbpx = bb[:px]
		bbpy = bb[:py]
			
		bbvx = bb[:vx]
		bbvy = bb[:vy]
			
		distance = Math::sqrt(
			(bapx - bbpx)*(bapx - bbpx) + (bapy - bbpy)*(bapy - bbpy)
		)*1.0
			
		# normal vector
		nx = ((bbpx - bapx)*1.0) / distance
		ny = ((bbpy - bapy)*1.0) / distance
			
		# tangent vector
		tx = -ny
		ty = nx
			
		# tangent response
		ta = bavx * tx + bavy * ty
		tb = bbvx * tx + bbvy * ty
			
		# normal response
		na = bavx * nx + bavy * ny
		nb = bbvx * nx + bbvy * ny
		
	
		total_mass = ba[:m] + bb[:m]
		ma = (na * (ba[:m] - bb[:m]) + 2.0 * bb[:m] * nb) / total_mass
		mb = (nb * (bb[:m] - ba[:m]) + 2.0 * ba[:m] * na) / total_mass
		
		
		if Bodies::body_static?(ba)
			# bb is dynamic
			CollisionShapes::collision_shape_translate(
				sb, 
				manifold[:penetration]*manifold[:normal][:x], 
				manifold[:penetration]*manifold[:normal][:y]
			)
			
			bb[:px] = sb[:centroid][:x]
			bb[:py] = sb[:centroid][:y]
			
			bb[:vx] = tx * tb + nx * mb
			bb[:vy] = ty * tb + ny * mb
		else
			if Bodies::body_static?(bb)
				# ba is dynamic
				CollisionShapes::collision_shape_translate(
					sa, 
					-manifold[:penetration]*manifold[:normal][:x], 
					-manifold[:penetration]*manifold[:normal][:y]
				)
				
				ba[:px] = sa[:centroid][:x]
				ba[:py] = sa[:centroid][:y]
			
				ba[:vx] = tx * ta + nx * ma
				ba[:vy] = ty * ta + ny * ma
			else
				# both are dynamic
				CollisionShapes::collision_shape_translate(
					sa, 
					-manifold[:penetration]*manifold[:normal][:x], 
					-manifold[:penetration]*manifold[:normal][:y]
				)
				
				ba[:px] = sa[:centroid][:x]
				ba[:py] = sa[:centroid][:y]
			
				ba[:vx] = tx * ta + nx * ma
				ba[:vy] = ty * ta + ny * ma
				
				CollisionShapes::collision_shape_translate(
					sb, 
					manifold[:penetration]*manifold[:normal][:x], 
					manifold[:penetration]*manifold[:normal][:y]
				)
			
				bb[:px] = sb[:centroid][:x]
				bb[:py] = sb[:centroid][:y]
			
				bb[:vx] = tx * tb + nx * mb
				bb[:vy] = ty * tb + ny * mb
			end
		end
		
		# finally apply the restitution
		e = [ba[:e], bb[:e]].min()
		ba[:vx] *= e
		ba[:vy] *= e
		bb[:vx] *= e
		bb[:vy] *= e
	end


end
