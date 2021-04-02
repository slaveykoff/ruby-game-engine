#!/usr/bin/env ruby

require_relative './Utils.rb'

module IntegratorUtils

	def self.explicit_euler(dt, px, py, vx, vy, fx, fy, m)
		fpx = px + vx*dt
		fpy = py + vy*dt
		fvx = vx + fx*dt*(1.0/m)
		fvy = vy + fy*dt*(1.0/m)
		
		return {
			px: fpx,
			py: fpy,
			vx: fvx,
			vy: fvy
		}
	end

	
	def self.implicit_euler(dt, px, py, vx, vy, fx, fy, m)
		fvx = vx + fx*dt*(1.0/m)
		fvy = vy + fy*dt*(1.0/m)
		fpx = px + vx*dt
		fpy = py + vy*dt
	
		return {
			px: fpx,
			py: fpy,
			vx: fvx,
			vy: fvy
		}
	end
	
end
