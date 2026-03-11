# frozen_string_literal: true

require 'app/bezier'

COLOR_NORMAL = { r: 200, g: 200, b: 200, a: 100 }.freeze
COLOR_HIGHLIGHT = { r: 200, g: 200, b: 200, a: 255 }.freeze
COLOR_HOVER = { r: 200, g: 200, b: 200, a: 160 }.freeze

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
  [hours, minutes, secs]
end

def format_time(seconds)
  hours, minutes, seconds = time_segments(seconds)
  format('%<hours>02d:%<minutes>02d:%<seconds>02d',
         hours: hours, minutes: minutes, seconds: seconds)
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
    path: :solid
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
    path: :solid
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
    path: :solid
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
    path: :solid
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
    path: :solid
  }
end

def render_targets_ready?(args)
  return args.outputs.render_targets.ready?(:triangle) && args.outputs.render_targets.ready?(:reset_btn)
end

def tick(args)
  args.outputs.background_color = Array.new(3, 33) << 255
  if Kernel.tick_count.zero?
    make_trigangle_rt(args)
    make_reset_btn_rt(args)
  end
  if !render_targets_ready?(args)
    args.outputs.labels << { x: Grid.w.half, y: Grid.h.half,
                             anchor_x: 0.5, anchor_y: 0.5,
                             **COLOR_NORMAL, size_px: 30, text: 'Loading' }
                           .merge(a: Math.sin(Kernel.tick_count / 20).remap(-1, 1, 30, 255))
    return
  end

  args.state.timer ||= Timer.new()
  args.state.timer_control ||= TimerControl.new(args.state.timer, x: Grid.w / 2, y: Grid.h / 2)
  args.state.mode_button ||= ModeButton.new(size: 40)
  args.state.reset_button ||= ResetButton.new(x: Grid.w, w: 40, h: 40)
  args.state.controls ||= [args.state.timer_control, args.state.mode_button, args.state.reset_button]

  # UPDATE
  args.state.controls.each do |c|
    c.tick(args)
  end
  args.outputs.debug << format('%.4f', args.state.timer.elapsed())

  # DRAW
  args.state.controls.each do |c|
    c.draw(args)
  end

  # INPUT
  args.state.controls.each do |c|
    break if c.handle_input(args)
  end
end

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

  def color=(val)
    @r = val.r
    @g = val.g
    @b = val.b
    @a = val.a
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
    args.outputs.sprites << self
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

class Timer
  attr_reader :running_time_added

  def initialize
    @start = Time.now
    @end = Time.now
    @mode = :up
    @state = :stopped
    @running_time_added = 0
    @running_start_time = nil
  end

  def reset
    @start = Time.now
    @end = @start
    @state = :stopped
    @mode = :up
    @running_time_added = 0
    @running_start_time = nil
  end

  def elapsed
    @end - @start
  end

  def elapsed=(new_elapsed)
    return unless stopped?

    @end = @start + new_elapsed.floor
  end

  # add elapsed time
  def <<(secs)
    return unless running?

    new_elapsed = elapsed() + secs

    return unless new_elapsed.positive?

    if mode_up?
      @start = @end - new_elapsed
    else
      @end = @start + new_elapsed
    end
    @running_time_added += secs
  end

  def running_elapsed
    Time.now - @running_start_time
  end

  def running?
    @state == :running
  end

  def stopped?
    @state == :stopped
  end

  def mode_up?
    @mode == :up
  end

  def mode_down?
    @mode == :down
  end

  def toggle_state
    if stopped?
      el = elapsed()
      if @mode == :up
        @end = Time.now
        @start = @end - el
      else
        @start = Time.now
        @end = @start + el
      end
      @state = :running
      @running_start_time = Time.now
    elsif running?
      @state = :stopped
    end
  end

  def toggle_mode
    el = elapsed()
    if @mode == :down
      @mode = :up
      @end = Time.now
      @start = @end - el
    elsif @mode == :up
      @mode = :down
      @start = Time.now
      @end = @start + el
    end
  end

  def tick
    return unless running? #&& Kernel.tick_count.zmod?(30)

    if mode_up?
      @end = Time.now
    elsif mode_down?
      @start = Time.now
      if elapsed() <= 0
        toggle_state()
        @start = @end
      end
    end
  end
end

class TimerControl < Control
  attr_reader :bezier_control_points, :timer, :size_perc

  def initialize(timer, x: 0, y: 0)
    super(x: x, y: y)
    @timer = timer
    @size_perc = 0.5
    @visual = NumberTextVisual.new(self)
    self.color = (COLOR_NORMAL)
    calc_bezier_control_points()
    @indicators = []
  end

  def tick(args)
    super(args)
    @timer.tick

    self.color = if @timer.running?
                   COLOR_HIGHLIGHT
                 elsif @hover
                   COLOR_HOVER
                 else
                   COLOR_NORMAL
                 end

    @indicators.each do |ind|
      ind.y += ind.dir * 5
      ind.a -= 30
    end
    @indicators.reject! do |ind|
      ind.a <= 0
    end
  end

  def draw(args)
    @visual.draw(args)
    args.outputs.solids << @indicators
    if @timer.running? && @timer.running_time_added != 0
      h, m, s = time_segments(@timer.running_time_added.abs)
      sign = @timer.running_time_added.positive? ? '+' : '-'
      text = [h, m, s].zip(%w[h m s]).reject { |el| el[0].zero? }.map(&:join).join
      args.outputs.labels << {
        x: 10.from_right,
        y: 10.from_top,
        anchor_x: 1,
        anchor_y: 1,
        **COLOR_NORMAL,
        font: @font,
        size_px: 30,
        text: "#{sign}#{text}"
      }
    end
  end

  def calc_bezier_control_points
    margin = [150, 150]
    @bezier_control_points = [
      [@x - @w / 2 - margin.x, @y],
      [@x - @w / 2 - margin.x, @y - @h / 2 - margin.y],
      [@x + @w / 2 + margin.x, @y - @h / 2 - margin.y],
      [@x + @w / 2 + margin.x, @y]
    ]
  end

  def handle_input(args)
    super(args)
    if args.inputs.keyboard.key_down.r
      @timer.reset()
      return true
    end

    # if args.inputs.keyboard.ctrl && args.inputs.mouse.wheel != nil
    if !@hover && !args.inputs.mouse.wheel.nil?
      @size_perc = (@size_perc + args.inputs.mouse.wheel.y / 10).clamp(0, 1)
      @visual.update_size()
      calc_bezier_control_points()
      return true
    end

    if args.inputs.keyboard.key_down.space
      @timer.toggle_state()
      return true
    end

    return false unless @hover

    # click
    if args.inputs.mouse.click
      @timer.toggle_state()
      return true
    end

    # wheel
    unless args.inputs.mouse.wheel.nil?
      wheel_y = args.inputs.mouse.wheel.y

      offset = args.inputs.mouse.x - (@x - @w / 2)
      over_at = 2 - (offset / (@w / 3)).floor # h -> 2, m -> 1, s -> 0

      if @timer.stopped?
        h, m, s = time_segments(@timer.elapsed)
        if over_at == 2
          # hour
          h += wheel_y
          h = h.clamp_wrap(0, 59)
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
        @timer.elapsed = new_elapsed
      else
        add_secs = wheel_y * (60**over_at) # 60^2 = 3600, 60^1 = 60, 60^0 = 1
        @timer << add_secs
      end
      spawn_indicator(over_at, wheel_y)

      return true
    end
    return false
  end

  def spawn_indicator(over_at, y_dir)
    dir = (y_dir / y_dir.abs)
    over = over_at.remap(2, 0, -1, 1)
    x = @x + @w * (over * 0.38)
    y = @y + dir * @h / 2
    @indicators << {
      x: x,
      y: y,
      w: 10,
      h: 10,
      anchor_x: 0.5,
      anchor_y: 0.5,
      **COLOR_HIGHLIGHT,
      path: :solid,
      dir: dir,
      created_at: Kernel.tick_count
    }
  end

  class NumberTextVisual

    SIZE_PX_MIN = 90
    SIZE_PX_MAX = 200

    def initialize(control)
      @control = control
      @font = 'fonts/Sono-Regular.ttf'
      update_size()
    end

    def update_size
      @size_px = @control.size_perc.remap(0, 1, SIZE_PX_MIN, SIZE_PX_MAX)
      @control.w, @control.h = GTK.calcstringbox(
        format_time(0),
        size_px: @size_px, font: @font
      )
    end

    def draw(args)
      args.outputs.labels << {
        x: @control.x,
        y: @control.y,
        anchor_x: 0.5,
        anchor_y: 0.5,
        **@control.color,
        font: @font,
        size_px: @size_px,
        text: format_time(@control.timer.elapsed())
      }
    end
  end
end

$gtk.reset
