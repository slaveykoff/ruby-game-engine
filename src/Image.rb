#!/usr/bin/env ruby

require 'chunky_png'
require 'rmagick'
require 'chunky_png/rmagick'

require 'sdl2'
require_relative './Renderer2D.rb'

module Image
	
	SDL2::IMG::init(SDL2::IMG::INIT_PNG)
	SDL2::IMG::init(SDL2::IMG::INIT_JPG)
	
	# file formats
	PNG = "png"
	JPG = "jpeg"
	
	#color spaces
	RGB  = Magick::RGBColorspace
	GRAY = Magick::GRAYColorspace
	
	#effects
	SHARPEN   = :sharpen
	BLUR      = :blur_image
	QUANTIZE  = :quantize
	POSTERIZE = :posterize

	def self.image_new(w, h, background_color = "rgba(0,0,0,0)", format = PNG, colorspace = RGB, depth = 16)
		return Magick::Image.new(w,h) {
			self.background_color = background_color
			self.format = format
			self.colorspace = colorspace
			self.depth = depth
		}
	end
	
	def self.image_load(filepath)
		return Magick::ImageList.new(filepath)[0]
	end

	def self.image_delete(image)
		image.destroy!()
		return nil
	end
	
	def self.image_metadata(image)
		return {
			w: image.columns,
			h: image.rows,
			depth: image.depth,
			format: image.format,
			#pitch: s.pitch,
			bitspp: image[:depth]
			#bytespp: s.bytes_per_pixel
		}
	end

	def self.image_save(image, filepath, format)
		image.write("#{format}:#{filepath}")
		return filepath
	end

	def self.image_save_png(image, filepath)
		return image_save(image, filepath, PNG)
	end
	
	# return array of Magick::Pixel
	def self.image_pixels_read(image)
		image_md = image_metadata(image)
		return image.get_pixels(0,0,image_md[:w],image_md[:h])
	end
	
	# pixels = array of Magick::Pixel
	def self.image_pixels_write(image, pixels)
		image_md = image_metadata(image)
		image.store_pixels(0,0,image_md[:w],image_md[:h],pixels)
	end
	
	def self.image_pixels_each(image)
		return if !block_given?()
		pixels = image_pixels_read(image)
		w = image.columns
		pixels.each_index do |i|
			p = pixels[i]
			x = i % w
			y = (i - x) / w
			yield p,x,y
		end
	end
	
	
	def self.image_pixel_read(image, x, y)
		return image.pixel_color(x,y)
	end
	
	# new_color = "white" or "rgba(r,g,b,a)"
	def self.image_pixel_write(image, x, y, new_color)
		return image.pixel_color(x,y,new_color)
	end
	
	# make the image transparent
	def self.image_transparent(image)
		return image.transparent('white', alpha: Magick::TransparentAlpha)
	end
	
	def self.image_show(image)
		image.display()
	end
	
	def self.image_effect(image, effect, effect_args)
		return image.send(effect, *effect_args)
	end
	
	# b to a
	# a is src
	# b is dst
	# Note sometimes, use Image::image_transparent() prior to this method, if you want to blend colors from a to b and vice versa image
	def self.image_composite(src, dst, compositeOp, gravity = Magick::CenterGravity)
		return src.composite(dst, gravity, compositeOp)
	end
	
	
	def self.image_composite_src_in(src_image, dst_image)
		return image_composite(src_image, dst_image, Magick::AtopCompositeOp)
	end
	
	# assumes the image is RGBA with depth 32
	def self.image_to_surface(image, blend_mode = SDL2::BlendMode::BLEND)
		surface = SDL2::Surface::from_string(
			image.export_pixels_to_str(0, 0, image.columns, image.rows, "RGBA", Magick::CharPixel),
			image.columns,
			image.rows,
			32,
			nil,
			0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000
		)		
		surface.blend_mode = blend_mode
		return surface
	end
	
	def self.image_size(image)
		return {
			w: image.columns,
			h: image.rows
		}
	end
	
	def self.image_to_texture(image, renderer)
		return renderer_surface_to_texture(renderer, Image::image_to_surface(image), true)
	end
	
	def self.surface_to_image(surface, depth = nil)
		w = surface.w
		h = surface.h
		d = ((depth.nil?) ? surface.bits_per_pixel : depth)
		image = image_new(w,h,"rgba(0,0,0,0)",PNG,RGB,d)
		
		surface_pixels_str = nil
		if surface.must_lock?()
			surface.lock()
			surface_pixels_str = surface.pixels
			surface.unlock()
		else
			surface_pixels_str = surface.pixels
		end
		image.import_pixels(0, 0, w, h, "RGBA", surface_pixels_str, Magick::CharPixel)
		return image
	end
	
	# color = string in the format "rgba(0,0,0,0)"
	def self.image_draw_line(image, x1, y1, x2, y2, color)
		draw = Magick::Draw.new()
		draw.stroke(color)
		draw.line(x1, y1, x2, y2)
		draw.draw(image)
		return image
	end
end
