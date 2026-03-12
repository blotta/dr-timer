class Control
  attr_accessor :x, :y, :w, :h, :r, :g, :b, :a, :anchor_x, :anchor_y

  attr_reader :hover

  def initialize(x: 0, y: 0, w: 20, h: 20, anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255, a: 255)
    @x = x
    @y = y
    @w = w
    @h = h
    @r = r
    @g = g
    @b = b
    @a = a
    @anchor_x = anchor_x
    @anchor_y = anchor_y
  end

  def color
    { r: @r, g: @g, b: @b, a: @a }
  end

  def color=(value)
    @r = value.r
    @g = value.g
    @b = value.b
    @a = value.a
  end

  def rect
    {
      x: @x,
      y: @y,
      w: @w,
      h: @h,
      anchor_x: @anchor_x,
      anchor_y: @anchor_y
    }
  end

  def tick(args)
    args.outputs.debug << "#{self.class} hover #{@hover}"
  end

  def draw(args); end

  def handle_input(args)
    @hover = point_inside?(args.inputs.mouse)
  end

  def point_inside?(p)
    p.inside_rect? self
  end
end
