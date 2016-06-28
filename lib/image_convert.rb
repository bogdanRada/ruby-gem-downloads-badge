require 'rsvg2'
class ImageConvert
  def self.svg_to_png(svg, width = nil , height = nil)
    svg = RSVG::Handle.new_from_data(svg)
    width   = width  ||=136
    height  = height ||=20
    surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, width, height)
    context = Cairo::Context.new(surface)
    context.render_rsvg_handle(svg)
    b = StringIO.new
    surface.write_to_png(b)
    return b.string
  end
end
