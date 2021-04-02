#!/usr/bin/env ruby

######################
#  Unused class.
#  Left here
#  just for
#  reference
#  regarding
#  surface
#  read and write
#  of pixels
#
#
#
#
######################

require 'chunky_png'
require 'rmagick'
require 'chunky_png/rmagick'
require 'sdl2'

require_relative './Renderer2D.rb'

SDL2::IMG::init(SDL2::IMG::INIT_PNG)
SDL2::IMG::init(SDL2::IMG::INIT_JPG)

BIG_ENDIAN        = 0
LITTLE_ENDIAN     = 0

ENDIANESS         = LITTLE_ENDIAN

=begin
	#if SDL_BYTEORDER == SDL_BIG_ENDIAN
		rmask = 0xff000000;
		gmask = 0x00ff0000;
		bmask = 0x0000ff00;
		amask = 0x000000ff;
	#else -> this mask is mine !!!
		rmask = 0x000000ff;
		gmask = 0x0000ff00;
		bmask = 0x00ff0000;
		amask = 0xff000000;
	#endif
=end

module ImageUtils

	# Image formats
	PNG = "png"
	JPG = "jpeg"

	TEXTURE_STATIC    = SDL2::Texture::ACCESS_STATIC
	TEXTURE_TARGET    = SDL2::Texture::ACCESS_TARGET
	TEXTURE_STREAMING = SDL2::Texture::ACCESS_STREAMING

	FORMAT_RGBA8888   = SDL2::PixelFormat::RGBA8888
	FORMAT_ARGB8888   = SDL2::PixelFormat::ARGB8888

	$unpacked_values = {}
	$packed_pixels = []
	
	def self.calculate_packed_pixel_values()
		256.times do |i|
			$packed_pixels[i] = [i].pack('C')
			$unpacked_values[$packed_pixels[i]] = i
		end
	end

####### TEXTURE START #######
	def self.texture_load(renderer, filepath)
		r_impl = renderer[:impl]
		texture = r_impl.load_texture(filepath)
		return texture
	end
	
	def self.texture_delete(texture)
		texture.destroy()
		surface = nil
	end
	
	def self.texture_size(texture)
		return {
			w: texture.w,
			h: texture.h
		}
	end
	
	def self.texture_metadata(t)
		return {
			w: t.w,
			h: t.h,
			format: t.format,
			access: t.access_pattern
		}
	end
####### TEXTURE END #######
####### SURFACE START ##########
	def self.surface_load(filepath)
		surface = SDL2::Surface::load(filepath)
		return surface
	end
	
	# pixels array of {r, g, b, a}
	def self.surface_new(pixels, w, h, depth, pitch)
		pixels_string = _pixels_to_string(pixels)
		if ENDIANESS == LITTLE_ENDIAN
			surface = SDL2::Surface::from_string(pixels_string, w, h, depth, pitch , 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000)
		else
			surface = SDL2::Surface::from_string(pixels_string, w, h, depth, pitch , 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff)
		end
		return surface
	end
	
	def self.surface_delete(surface)
		surface.destroy()
		surface = nil
	end
	
	def self.surface_size(surface)
		return {
			w: surface.w,
			h: surface.h
		}
	end
	
	def self.surface_metadata(s)
		return {
			w: s.w,
			h: s.h,
			# higly unlikely to works always
			depth: s.bits_per_pixel,
			pitch: s.pitch,
			bitspp: s.bits_per_pixel,
			bytespp: s.bytes_per_pixel
		}
	end
	
	# return all of the surface's pixels as an array of {r,g,b,a}
	def self.surface_read(surface)
		calculate_packed_pixel_values()
		w = surface.w
		h = surface.h		
		depth = surface.bits_per_pixel
		pitch = surface.pitch
		orig_pixels = surface.pixels
		pixels_data = []
		pdlp = PixelDataLoaderProgress.new(orig_pixels.length())
		Utils::for(0, orig_pixels.length(), Utils::<, 4, lambda{|i|
			r = $unpacked_values[orig_pixels[i]]
			g = $unpacked_values[orig_pixels[i+1]]
			b = $unpacked_values[orig_pixels[i+2]]
			a = $unpacked_values[orig_pixels[i+3]]
			pixels_data << {
				r: r,
				g: g,
				b: b,
				a: a
			}
			pdlp.update(ImageUtils::PixelDataLoaderProgress::READ, i)
		})
		pdlp.stop()
		return pixels_data
	end
	
	# will delete the surface and create a new one with the same metadata as the original one, but with changed pixels
	def self.surface_write(surface, pixels)
		metadata = ImageUtils::surface_metadata(surface)
		surface_delete(surface)
		src_surface = ImageUtils::surface_new(
			pixels,
			metadata[:w], 
			metadata[:h], 
			metadata[:depth], 
			metadata[:pitch]
		)
		return src_surface
	end
########## SURFACE END #######
###### IMAGE START ######

	def self.image_new(w,h)
		image = Magick::Image.new(w,h)
		return image
	end

	def self.image_load(filepath)
		image = Magick::ImageList.new(filepath)[0]
		return image
	end
	
	def self.image_delete(image)
		image.destroy!()
		image = nil
	end
	
	def self.image_blur(image, radius, sigma)
		return image.blur_image(radius, sigma)
	end
	
	def self.image_sharpen(image, radius, sigma)
		return image.sharpen(radius, sigma)
	end
	
	def self.image_grayscale(image)
		return image.quantize(256, Magick::GRAYColorspace)
	end
	
	def self.surface_to_image(surface)
		#filename = Time.now().to_f() + rand()
		#filepath = "/tmp/#{filename}"
		#surface.write(filepath)
		#image = image_load(filepath)
		#File.delete(filepath)
		#return image
		throw "Not implemented!"
	end

	def self.image_to_surface(image, file_format = PNG)
		timer = Utils::Timer.new(0, nil)
		timer.start()
		filename = Time.now().to_f() + rand()
		filepath = "/tmp/#{filename}"
		image.write("#{file_format}:" + filepath)
		surface = surface_load(filepath)
		File.delete(filepath)
		timer.stop()
		puts "Image to Surface took: #{timer.duration.round(2)} seconds!"
		return surface
	end
	
	def self.image_to_texture(renderer, image)
		surface = image_to_surface(image)
		texture = surface_to_texture(renderer, surface)
		surface.destroy()
		return texture
	end

=begin
	# pixels = array of {r, g, b, a}
	def self.effect_blur(pixels, sigma, radius = 0.0)
		blob = _pixels_to_string(pixels)
		_image = Magick::ImageList.new('/home/dslaveykov/Downloads/misc/test_cp.jpg')[0]
		orig_blob = _image.to_blob()
		throw "SIZE DIFF! [#{orig_blob.length - blob.length()}]" if orig_blob.length != blob.length()
		image = Magick::Image.from_blob(blob)
		
		# img.quantize(number_colors=256, colorspace=RGBColorspace, dither=RiemersmaDitherMethod, tree_depth=0, measure_error=false) 
		#image.to_blob().each_char do |c|
		#	puts c.unpack("B*")[0].to_s().to_i(2)
		#end
		image = image.blur_image(radius, sigma)
		pixels_string = image.to_blob()
		pixels_data = []
		Utils::for(0, orig_pixels.length(), Utils::<, 4, lambda{|i|
			r = $unpacked_values[orig_pixels[i]]
			g = $unpacked_values[orig_pixels[i+1]]
			b = $unpacked_values[orig_pixels[i+2]]
			a = $unpacked_values[orig_pixels[i+3]]
			pixels_data << {
				r: r,
				g: g,
				b: b,
				a: a
			}
		})
		return pixels_data
	end
=end
###### IMAGE END ######
####### PRIVATE START #######
private
	def self._pixels_to_string(pixels_data)
		if $packed_pixels.nil?()
			puts "Calculating packed pixel values - START ..."
			calculate_packed_pixel_values()
			puts "Calculating packed pixel values - DONE!"
		end
		pixels_string = ""
		pdlp = PixelDataLoaderProgress.new(pixels_data.length())
		Utils::for(0, pixels_data.length(), Utils::<, 1, lambda{|i|
			pixel = pixels_data[i]
			r = $packed_pixels[pixel[:r]]
			g = $packed_pixels[pixel[:g]]
			b = $packed_pixels[pixel[:b]]
			a = $packed_pixels[pixel[:a]]
			# NEVEN, EVER, EVER use += for concatenation, always use <<
			# << is multiple (100-1000) times faster
			pixels_string << "#{r}#{g}#{b}#{a}"
			pdlp.update(ImageUtils::PixelDataLoaderProgress::WRITE, i)
		})
		pdlp.stop()
		return pixels_string
	end
	
	def self.surface_to_texture(renderer, surface)
		r_impl = renderer[:impl]
		return r_impl.create_texture_from(surface)
	end
	
	class PixelDataLoaderProgress
		READ = 0
		WRITE = 1
	
		def initialize(pixels_count)
			@pixels_count = pixels_count
			@start_time = Time.now().to_f()
			@interval = 1.0
			@end_time = @start_time + @interval
			@runtime = 0
		end
		
		def update(operation, current_idx)
			current_time = Time.now().to_f()
			percentage = ((current_idx*1.0 / @pixels_count)*100).round(2)
			if current_time >= @end_time
				@runtime += @interval
				puts "Pixels read #{percentage}%" if operation == READ
				puts "Pixels written #{percentage}%" if operation == WRITE
				@start_time = current_time
				@end_time = @start_time + @interval
			end
		end
		
		def stop()
			puts "Operation done in #{@runtime} seconds"
		end
		
	end
	
end
####### PRIVATE END #######

