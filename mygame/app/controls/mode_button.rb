require_relative 'control'
require 'app/sprite_rt'

class ModeButton < Control
  attr_sprite

  def initialize(x: 0, y: 0, size: 100)
    super(x: x, y: y, w: size, h: size, anchor_x: 0.5, anchor_y: 0.5, **COLOR_NORMAL)
    @angle = 0
    @path = :triangle
  end

  def tick(args)
    super(args)
    self.color = @hover ? COLOR_HOVER : COLOR_NORMAL
    p = point_on_bezier(*args.state.timer_control.bezier_control_points, 0 + args.state.timer_control.size_perc * 0.3)
    @x = @x.lerp(p.x, 0.2)
    @y = @y.lerp(p.y, 0.2)
    @angle = @angle.lerp(args.state.timer.mode_up? ? 90 : 270, 0.2)
    @w = 50 + args.state.timer_control.size_perc * 30
    @h = @w
  end

  def draw(args)
    @path = SpriteRT.make_triangle_rt(args)
    if args.outputs.render_targets.ready?(@path)
      args.outputs.sprites << self
    end
  end

  def handle_input(args)
    super(args)
    return false unless @hover

    if args.inputs.mouse.click
      args.state.timer.toggle_mode()
      true
    end
  end

  def point_inside?(p)
    Geometry.point_inside_circle?(p, { x: @x, y: @y }, @w / 2)
  end
end
