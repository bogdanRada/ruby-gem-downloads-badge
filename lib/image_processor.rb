# frozen_string_literal: true
require_relative './helper'
require 'rsvg2'
# Initializes the instance with the params from controller
class ImageProcessor
  include Helper
  # Initializes the instance with the params from controller, and will try to download the information about the rubygems
  # and then will try to download the badge to the output strea
  def initialize(input, mode, options = {})
    @svg = input
    @mode = mode.to_s
    @mode = 'jpeg' if @mode == 'jpg'
    @options = options.is_a?(Hash) ? options.symbolize_keys : {}
    @ratio = @options[:ratio].present? ? options[:ratio].to_i : 1
    @handle = RSVG::Handle.new_from_data(@svg)
  end

  def process
    return unless %w(jpeg jpg png).include?(@mode)
    render_image
  end

  def render_image
    setup
    @context = create_context Cairo::FORMAT_ARGB32
    @context_target = @context.target
    @mode == 'png' ? render_png_memory : render_jpeg_image_from_file
  end

  def render_png_memory(output = StringIO.new)
    output.set_encoding('UTF-8') if output.is_a?(StringIO)
    @context_target.write_to_png(output)
    @context_target.finish
    output.is_a?(StringIO) ? output.string : output
  end

  def render_jpeg_image_from_file
    temp_path = create_temp_file('svg2')
    render_png_memory(temp_path)
    buffer_jpeg_from_file(temp_path)
  end

  def buffer_jpeg_from_file(temp_path)
    @pixbuf = Gdk::Pixbuf.new(temp_path)
    @pixbuf.save(temp_path, @mode)
    output = File.read(temp_path)
    FileUtils.rm_rf(temp_path)
    output
  end

  def render_jpeg_image_memory
    output =  render_png_memory
    @pixbuf = Gdk::Pixbuf.new(
    data:             output,
    colorspace:       :rgb,
    has_alpha:        false,
    bits_per_sample:  8,
    width:            @width,
    height:           @height,
    rowstride:        1
    )
    temp_path = create_temp_file('svg2')
    @pixbuf.save(temp_path, @mode)
    output = File.read(temp_path)
    FileUtils.rm_rf(temp_path)
    output
  end

  def setup
    @dim = @handle.dimensions
    @width = @dim.width * @ratio
    @height = @dim.height * @ratio
    surface_class_name = 'ImageSurface'
    @surface_class = Cairo.const_get(surface_class_name)
  end

  def create_context(arg)
    surface = @surface_class.new(arg, @width, @height)
    context = Cairo::Context.new(surface)
    context.scale(@ratio, @ratio)
    context.render_rsvg_handle(@handle)
    context
  end
end
