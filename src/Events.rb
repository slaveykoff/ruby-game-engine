#!/usr/bin/env ruby

require_relative './Utils.rb'
require 'sdl2'

module Events

	LEFT_MOUSE_BUTTON   = 1
	RIGHT_MOUSE_BUTTON  = 3
	MIDDLE_MOUSE_BUTTON = 2

	@keyboard = {}	
	@mouse    = {
		position: {
			x: -1,
			y: -1
		},
	}
	@gamepad  = {}

	# poll single event
	def self.poll_event()
		return event = SDL2::Event::poll()
	end
	
	# poll all events and update mouse/keyboard/gamepad state
	def self.update_hid()
		lbk = LEFT_MOUSE_BUTTON.to_s().to_sym()
		if !@mouse.key?(lbk)
			@mouse[lbk] = {
				pressed: false
			}
		end
		rbk = RIGHT_MOUSE_BUTTON.to_s().to_sym()
		if !@mouse.key?(rbk)
			@mouse[rbk] = {
				pressed: false
			}
		end
		mbk = MIDDLE_MOUSE_BUTTON.to_s().to_sym()
		if !@mouse.key?(mbk)
			@mouse[mbk] = {
				pressed: false
			}
		end
		loop do
			event = SDL2::Event::poll()
			# TODO
			has_key_event = false
			has_mouse_event = false
			if event.is_a?(SDL2::Event::KeyUp)
				has_key_event = true
				key = SDL2::Key::name_of(event.sym).downcase()
				# KEY UP
				# do we have such key in @keyboard
				if !@keyboard.key?(key)
					@keyboard[key] = {
						pressed: false,
						released: false,
						held: false
					}
				end
				@keyboard[key][:pressed] = false
				@keyboard[key][:released] = true
				@keyboard[key][:held] = false
			elsif event.is_a?(SDL2::Event::KeyDown)
				# KEY DOWN
				has_key_event = true
				key = SDL2::Key::name_of(event.sym).downcase()
				# do we have such key in @keyboard
				if !@keyboard.key?(key)
					@keyboard[key] = {
						pressed: false,
						released: false,
						held: false
					}
				end				
				was_previously_pressed = @keyboard[key][:pressed]
				@keyboard[key][:pressed] = true
				@keyboard[key][:released] = false
				@keyboard[key][:held] = was_previously_pressed
			elsif event.is_a?(SDL2::Event::MouseButton) || event.is_a?(SDL2::Event::MouseMotion) || event.is_a?(SDL2::Event::MouseWheel)
				mstate = SDL2::Mouse::state()
				@mouse[:position][:x] = mstate.x()
				@mouse[:position][:y] = mstate.y()
				# Note handle mice with 3 buttons
				@mouse[lbk][:pressed] = mstate.pressed?(LEFT_MOUSE_BUTTON)
				@mouse[rbk][:pressed] = mstate.pressed?(RIGHT_MOUSE_BUTTON)
				@mouse[mbk][:pressed] = mstate.pressed?(MIDDLE_MOUSE_BUTTON)
			end
			return if event.nil?()
		end
		# clear released flag
		if !has_key_event
			@keyboard.each do |k, v|
				v[:released] = false
			end
		end
	end
	
	def self.keyboard_key_pressed?(key)
		key = key.downcase()
		return false if !@keyboard.key?(key)
		return @keyboard[key][:pressed]
	end
	
	def self.keyboard_key_released?(key)
		key = key.downcase()
		return false if !@keyboard.key?(key)
		return @keyboard[key][:released]
	end
	
	def self.keyboard_key_held?(key)
		key = key.downcase()
		return false if !@keyboard.key?(key)
		return @keyboard[key][:held]
	end
	
	def self.mouse_button_pressed?(button)
		return @mouse[button.to_s().to_sym()][:pressed]
	end
	
	def self.mouse_button_held?(button)
		return mouse_button_pressed(button)
	end
	
	def self.mouse_button_released?(button)
		return @mouse[button.to_s().to_sym()][:released]
	end
	
	def self.mouse_position()
		return @mouse[:position]
	end
	
	# TODO - add gamepad methods

end
