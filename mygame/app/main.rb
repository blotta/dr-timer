require_relative "bezier"

COLOR_NORMAL = { r: 200, g: 200, b: 200, a: 100 }
COLOR_HIGHLIGHT = { r: 200, g: 200, b: 200, a: 255 }
COLOR_HOVER = { r: 200, g: 200, b: 200, a: 160 }

HOLE_PUNCH_BLENDMODE = Numeric.compose_blendmode(BLENDFACTOR_ZERO,
                                                 BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                                 BLENDOPERATION_ADD,
                                                 BLENDFACTOR_ZERO,
                                                 BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                                 BLENDOPERATION_ADD)

def time_segments(seconds)
  s = seconds
  hours = (s / 3600).floor
  minutes = ((s % 3600) / 60).floor
  secs = s % 60
  return hours, minutes, secs
end

def format_time(seconds)
  hours, minutes, seconds = time_segments(seconds)
  format("%02d:%02d:%02d", hours, minutes, seconds)
end

def make_trigangle_rt(args)
  size = 200
  p1 = { x: size / 2, y: 0 }
  p2 = Geometry.rotate_point(p1, 120)
  p3 = Geometry.rotate_point(p1, 240)
  args.outputs[:triangle].w = size
  args.outputs[:triangle].h = size
  args.outputs[:triangle].background_color = [0, 0, 0, 0]
  args.outputs[:triangle].primitives << {
    x: size / 2 + p1.x,
    y: size / 2 + p1.y,
    x2: size / 2 + p2.x,
    y2: size / 2 + p2.y,
    x3: size / 2 + p3.x,
    y3: size / 2 + p3.y,
    source_x: size / 2 + p1.x,
    source_y: size / 2 + p1.y,
    source_x2: size / 2 + p2.x,
    source_y2: size / 2 + p2.y,
    source_x3: size / 2 + p3.x,
    source_y3: size / 2 + p3.y,
    r: 255, g: 255, b: 255, a: 255,
    path: :solid,
  }

  # hole punch doesn't seem to work with triangles
  # args.outputs[:triangle].primitives << {
  #   x:  size / 2 + p1.x * 0.7,
  #   y:  size / 2 + p1.y * 0.7,
  #   x2: size / 2 + p2.x * 0.7,
  #   y2: size / 2 + p2.y * 0.7,
  #   x3: size / 2 + p3.x * 0.7,
  #   y3: size / 2 + p3.y * 0.7,
  #   source_x: size / 2 +  p1.x * 0.7,
  #   source_y: size / 2 +  p1.y * 0.7,
  #   source_x2: size / 2 + p2.x * 0.7,
  #   source_y2: size / 2 + p2.y * 0.7,
  #   source_x3: size / 2 + p3.x * 0.7,
  #   source_y3: size / 2 + p3.y * 0.7,
  #   # r: 33, g: 33, b: 33, a: 255,
  #   r: 0, g: 0, b: 0, a: 255,
  #   path: :solid,
  #   blendmode: HOLE_PUNCH_BLENDMODE
  # }
end

def make_reset_btn_rt(args)
  size = 200
  args.outputs[:reset_btn].w = size
  args.outputs[:reset_btn].h = size
  args.outputs[:reset_btn].background_color = [0, 0, 0, 0]
  args.outputs[:reset_btn].primitives << {
    x: size / 2,
    y: size / 2,
    w: size,
    h: size,
    anchor_x: 0.5,
    anchor_y: 0.5,
    r: 255, g: 255, b: 255, a: 255,
    path: :solid,
  }

  c = size * 0.3 / 2
  args.outputs[:reset_btn].primitives << {
    x: size / 2,
    y: size / 2,
    w: size - c * 2,
    h: size - c * 2,
    anchor_x: 0.5,
    anchor_y: 0.5,
    angle: 0,
    r: 0, g: 0, b: 0, a: 255,
    blendmode: HOLE_PUNCH_BLENDMODE,
    path: :solid,
  }

  inner_se = [size - c, c]
  args.outputs[:reset_btn].primitives << {
    x: inner_se.x,
    y: inner_se.y,
    w: c,
    h: c,
    anchor_x: 1,
    anchor_y: 1,
    angle: 0,
    r: 0, g: 0, b: 0, a: 255,
    blendmode: HOLE_PUNCH_BLENDMODE,
    path: :solid,
  }
  inner_nw = [c, size - c]
  args.outputs[:reset_btn].primitives << {
    x: inner_nw.x,
    y: inner_nw.y,
    w: c,
    h: c,
    anchor_x: 0,
    anchor_y: 0,
    angle: 0,
    r: 0, g: 0, b: 0, a: 255,
    blendmode: HOLE_PUNCH_BLENDMODE,
    path: :solid,
  }
end

def tick(args)
  if Kernel.tick_count == 0
    make_trigangle_rt(args)
    make_reset_btn_rt(args)
  end

  args.outputs.background_color = Array.new(3, 33) << 255

  args.state.timer ||= TimerControl.new(x: Grid.w / 2, y: Grid.h / 2)
  args.state.mode_button ||= ModeButton.new(size: 40)
  args.state.reset_button ||= ResetButton.new(x: Grid.w, w: 40, h: 40)
  args.state.controls ||= [args.state.timer, args.state.mode_button, args.state.reset_button]

  # UPDATE
  args.state.controls.each do |c|
    c.tick(args)
  end
  args.outputs.debug << format("%.4f", args.state.timer.elapsed())

  # DRAW
  args.state.controls.each do |c|
    c.draw(args)
  end

  # INPUT
  args.state.controls.each do |c|
    break if c.handle_input(args)
  end
end

$gtk.reset

class Control
  attr_accessor :x, :y, :w, :h, :r, :g, :b, :a, :anchor_x, :anchor_y

  attr_reader :hover

  def initialize(x: 0, y: 0, w: 20, h: 20, anchor_x: 0.5, anchor_y: 0.5, r: 255, g: 255, b: 255, a: 255)
    @x = x
    @y = y
    @w = w
    @h = h
    @anchor_x = anchor_x
    @anchor_y = anchor_y
  end

  def color
    return { r: @r, g: @g, b: @b, a: @a }
  end

  def color=(val)
    @r = val.r
    @g = val.g
    @b = val.b
    @a = val.a
  end

  def rect
    return {
             x: @x,
             y: @y,
             w: @w,
             h: @h,
             anchor_x: @anchor_x,
             anchor_y: @anchor_y,
           }
  end

  def tick(args)
    args.outputs.debug << "#{self.class} hover #{@hover}"
  end

  def draw(args)
  end

  def handle_input(args)
    @hover = self.point_inside?(args.inputs.mouse)
  end

  def point_inside?(p)
    return p.inside_rect? self
  end
end

class TimerControl < Control
  attr_accessor :text, :font,
                :blendmode_enum, :size_px, :size_enum, :alignment_enum,
                :vertical_alignment_enum

  attr_reader :mode, :bezier_control_points

  SIZE_PX_MIN = 90
  SIZE_PX_MAX = 200

  def primitive_marker
    :label
  end

  def initialize(x: 0, y: 0, size_px: 150)
    super(x: x, y: y)
    @start = Time.now
    @end = Time.now
    @mode = :up
    @state = :stopped
    @font = "fonts/Sono-Regular.ttf"
    self.color = (COLOR_NORMAL)
    set_size_px(size_px)
    calc_bezier_control_points()
  end

  def set_size_px(spx)
    @size_px = spx
    @w, @h = GTK.calcstringbox(
      format_time(0),
      size_px: @size_px, font: @font,
    )
  end

  def size_perc
    return (@size_px - SIZE_PX_MIN) / (SIZE_PX_MAX - SIZE_PX_MIN)
  end

  def text
    return format_time(elapsed())
  end

  def reset
    @start = Time.now
    @end = @start
    @state = :stopped
    @mode = :up
    self.color = COLOR_NORMAL
  end

  def elapsed
    return @end - @start
  end

  def toggle_state
    if @state == :stopped
      el = elapsed()
      if @mode == :up
        @end = Time.now
        @start = @end - el
      else
        @start = Time.now
        @end = @start + el
      end
      self.color = COLOR_HIGHLIGHT
      @state = :running
    elsif @state == :running
      self.color = COLOR_NORMAL
      @state = :stopped
    end
  end

  def toggle_mode
    @mode = @mode == :up ? :down : :up
    el = elapsed()
    if @mode == :up
      @end = Time.now
      @start = @end - el
    else
      @start = Time.now
      @end = @start + el
    end
  end

  def tick(args)
    super(args)

    if @state == :running
      self.color = COLOR_HIGHLIGHT
    else
      self.color = @hover ? COLOR_HOVER : COLOR_NORMAL
    end

    return unless @state == :running
    if @mode == :up
      @end = Time.now
    else
      @start = Time.now
      if elapsed() <= 0
        toggle_state()
        @start = @end
      end
    end
  end

  def draw(args)
    args.outputs.labels << self
  end

  def calc_bezier_control_points()
    margin = [150, 150]
    @bezier_control_points = [
      [@x - @w / 2 - margin.x, @y],
      [@x - @w / 2 - margin.x, @y - @h / 2 - margin.y],
      [@x + @w / 2 + margin.x, @y - @h / 2 - margin.y],
      [@x + @w / 2 + margin.x, @y],
    ]
  end

  def handle_input(args)
    super(args)
    if args.inputs.keyboard.key_down.r
      reset()
      return true
    end

    # if args.inputs.keyboard.ctrl && args.inputs.mouse.wheel != nil
    if !@hover && args.inputs.mouse.wheel != nil
      size_px = @size_px
      size_px += args.inputs.mouse.wheel.y * 6
      size_px = size_px.clamp(SIZE_PX_MIN, SIZE_PX_MAX)
      set_size_px(size_px)
      calc_bezier_control_points()
      return true
    end

    if args.inputs.keyboard.key_down.space
      toggle_state()
      return true
    end

    return false unless @hover

    # click
    if args.inputs.mouse.click
      toggle_state()
      return true
    end

    # wheel
    if args.inputs.mouse.wheel != nil
      wheel_y = args.inputs.mouse.wheel.y
      if @state == :stopped
        # reset milliseconds
        el = elapsed()
        el -= el - el.floor
        @start = @end - el
      end

      offset = args.inputs.mouse.x - (@x - @w / 2)
      over_at = 2 - (offset / (@w / 3)).floor # h -> 2, m -> 1, s -> 0

      if @state == :stopped
        h, m, s = time_segments(elapsed)
        if over_at == 2
          # hour
          h += wheel_y
          h = h.clamp_wrap(0, 99)
        elsif over_at == 1
          # minute
          m += wheel_y
          m = m.clamp_wrap(0, 59)
        else
          # second
          s += wheel_y
          s = s.clamp_wrap(0, 59)
        end
        new_elapsed = (h * 60 * 60) + (m * 60) + s
        @end = @start + new_elapsed
        return true
      else
        add_secs = wheel_y * (60 ** over_at) # 60^2 = 3600, 60^1 = 60, 60^0 = 1
        new_elapsed = elapsed() + add_secs
        new_elapsed = [new_elapsed, 0].max
        if @mode == :up
          @start = @end - new_elapsed
        else
          @end = @start + new_elapsed
        end
        return true
      end

      return false
    end
    return false
  end

  def serialize
    return {
             x: @x, y: @y,
             w: @w, h: @h,
             anchor_x: @anchor_x, anchor_y: @anchor_y,
             size_px: @size_px, font: @font,
             r: @r, g: @g, b: @b, a: @a,
             text: text(),
           }
  end

  def inspect
    serialize.to_s
  end
end

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
    p = point_on_bezier(*args.state.timer.bezier_control_points, 0 + args.state.timer.size_perc * 0.3)
    @x = @x.lerp(p.x, 0.2)
    @y = @y.lerp(p.y, 0.2)
    @angle = @angle.lerp(args.state.timer.mode == :up ? 90 : 270, 0.2)
    @w = 50 + args.state.timer.size_perc * 30
    @h = @w
  end

  def draw(args)
    args.outputs.sprites << self
  end

  def handle_input(args)
    super(args)
    return false unless @hover
    if args.inputs.mouse.click
      args.state.timer.toggle_mode()
      return true
    end
  end

  def point_inside?(p)
    return Geometry.point_inside_circle?(p, { x: @x, y: @y }, @w / 2)
  end
end

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

    p = point_on_bezier(*args.state.timer.bezier_control_points, 1 - args.state.timer.size_perc * 0.3)
    @x = @x.lerp(p.x, 0.2)
    @y = @y.lerp(p.y, 0.2)

    @angle = @angle.lerp(0, 0.2)
    @w = 40 + args.state.timer.size_perc * 20
    @h = @w
  end

  def draw(args)
    args.outputs.sprites << self
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
