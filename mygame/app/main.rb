COLOR_NORMAL = { r: 200, g: 200, b: 200, a: 100 }
COLOR_HIGHLIGHT = { r: 200, g: 200, b: 200, a: 255 }
COLOR_HOVER = { r: 200, g: 200, b: 200, a: 160 }

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

def tick(args)
  args.outputs.background_color = Array.new(3, 33) << 255

  args.state.timer ||= TimerControl.new(x: Grid.w / 2, y: Grid.h / 2)
  args.state.mode_button ||= ModeButton.new(size: 40)
  args.state.reset_button ||= ResetButton.new(w: 40, h: 40)
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

  def initialize(x: 0, y: 0, w: 20, h: 20, anchor_x: 0.5, anchor_y: 0.5)
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

  attr_reader :mode

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
  end

  def set_size_px(spx)
    @size_px = spx
    @w, @h = GTK.calcstringbox(
      format_time(0),
      size_px: @size_px, font: @font,
    )
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

  def handle_input(args)
    super(args)
    if args.inputs.keyboard.key_down.r
      reset()
      return true
    end

    if args.inputs.keyboard.ctrl && args.inputs.mouse.wheel != nil
      size_px = @size_px
      size_px += args.inputs.mouse.wheel.y * 6
      size_px = size_px.clamp(90, 200)
      set_size_px(size_px)
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
  def initialize(x: 0, y: 0, size: 40)
    # center -> x, y
    super(x: x, y: y)
    @size = size
    @ssize = 8
    @sx_off = 2
    @sy_off = 2
    @angle = 0
    self.color = COLOR_NORMAL

    @p1 = { x: @size / 2, y: 0 }
    @p2 = Geometry.rotate_point(@p1, 120)
    @p3 = Geometry.rotate_point(@p1, 240)
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

  def sprite(args)
    off1 = Geometry.rotate_point(@p1, @angle)
    off2 = Geometry.rotate_point(@p2, @angle)
    off3 = Geometry.rotate_point(@p3, @angle)
    return {
             x: @x + off1.x,
             y: @y + off1.y,
             x2: @x + off2.x,
             y2: @y + off2.y,
             x3: @x + off3.x,
             y3: @y + off3.y,
             source_x: 0,
             source_y: 0,
             source_x2: 0,
             source_y2: 0,
             source_x3: 0,
             source_y3: 0,
             r: @r, g: @g, b: @b, a: @a,
             path: :solid,
           }
  end

  def tick(args)
    super(args)
    self.color = @hover ? COLOR_HOVER : COLOR_NORMAL
    @x = args.state.timer.x - args.state.timer.w / 2 - 50
    @y = args.state.timer.y
    @angle = @angle.lerp(args.state.timer.mode == :up ? 90 : 270, 0.2)
  end

  def draw(args)
    args.outputs.sprites << self.sprite(args)
  end

  def handle_input(args)
    super(args)
    return false unless @hover
    if args.inputs.mouse.click
      puts "toggle mode"
      args.state.timer.toggle_mode()
      return true
    end
  end

  def point_inside?(p)
    return Geometry.point_inside_circle?(p, { x: @x, y: @y }, @size / 2)
  end
end

class ResetButton < Control
  attr_sprite

  def primitive_marker
    :solid
  end

  def initialize(x: 0, y: 0, w: 0, h: 0)
    super(x: x, y: y, w: w, h: h, anchor_x: 0, anchor_y: 0.5)
    @angle = 0
    @path = :solid
    self.color = COLOR_NORMAL
  end

  def tick(args)
    super(args)
    self.color = @hover ? COLOR_HOVER : COLOR_NORMAL

    @x = args.state.timer.x + args.state.timer.w / 2 + 50
    @y = args.state.timer.y
    @angle = @angle.lerp(0, 0.2)
  end

  def draw(args)
    args.outputs.sprites << self
    p = self.rect.rect_center_point
    args.outputs.sprites << {
      x: p.x,
      y: p.y,
      w: @w * 0.7,
      h: @h * 0.7,
      anchor_x: 0.5,
      anchor_y: 0.5,
      angle: @angle,
      path: :solid,
      blendmode: 4
    }.merge(self.color)
  end

  def handle_input(args)
    super(args)
    return false unless @hover
    if args.inputs.mouse.click
      puts "here"
      args.state.timer.reset()
      @angle = -180
    end
  end
end
