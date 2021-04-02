#!/usr/bin/env ruby

require_relative './Utils.rb'
require 'sdl2'

SDL2::init(SDL2::INIT_EVERYTHING)

def window_new(t, w, h, f)
	impl = SDL2::Window::create(t, SDL2::Window::POS_CENTERED, SDL2::Window::POS_CENTERED, w, h, ((f) ? SDL2::Window::Flags::FULLSCREEN : SDL2::Window::Flags::HIDDEN))
	window = {
		title:      t,
		width:      w,
		height:     h,
		fullscreen: f,
		impl:       impl
	}
	
	return window
end

def window_delete(w)
	w = nil
end

def window_show(w)
	w[:impl].show()
end

def window_hide(w)
	w[:impl].hide()
end

def window_size(w)
    return {
        w: w[:width],
        h: w[:height]
    }
end

