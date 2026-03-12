require_relative 'control'
require 'app/sprite_rt'

class ResetButton < Control
  attr_sprite

  def initialize(x: 0, y: 0, w: 0, h: 0)
    super(x: x, y: y, w: w, h: h, anchor_x: 0.5, anchor_y: 0.5, **COLOR_NORMAL)
    @angle = 0
    @path = :reset_btn
  end

  def tick(args)
    super(args)
    self.color = @hover ? COLOR_HOVER : COLOR_NORMAL

    p = point_on_bezier(*args.state.timer_control.bezier_control_points, 1 - args.state.timer_control.size_perc * 0.3)
    @x = @x.lerp(p.x, 0.2)
    @y = @y.lerp(p.y, 0.2)

    @angle = @angle.lerp(0, 0.2)
    @w = 40 + args.state.timer_control.size_perc * 20
    @h = @w
  end

  def draw(args)
    @path = SpriteRT.make_reset_btn_rt(args)
    if args.outputs.render_targets.ready?(@path)
      args.outputs.sprites << self
    end
  end

  def handle_input(args)
    super(args)
    return false unless @hover

    if args.inputs.mouse.click
      args.state.timer.reset()
      @angle = -180
    end
  end
end
