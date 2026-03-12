require_relative 'control'

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

class TimerControl < Control
  attr_reader :bezier_control_points, :timer, :size_perc

  def initialize(timer, x: 0, y: 0)
    super(x: x, y: y)
    @timer = timer
    @size_perc = 0.5
    @visual = BoxesVisual.new(self)
    self.color = (COLOR_NORMAL)
    calc_bezier_control_points()
    @indicators = []
  end

  def tick(args)
    super(args)
    @timer.tick
    @visual.tick args

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

    if args.inputs.keyboard.key_down.tab
      @visual = if @visual.instance_of?(NumberTextVisual)
                  BoxesVisual.new(self)
                else
                  NumberTextVisual.new(self)
                end
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

  class BoxesVisual
    WIDTH_MIN = Grid.w * 0.5
    WIDTH_MAX = Grid.w * 0.8

    def initialize(control)
      @control = control
      @rects = {}
      @boxes = { s: [], m: [], h: [] }
      update_size()
    end

    def update_size
      base_w = @control.size_perc.remap(0, 1, WIDTH_MIN, WIDTH_MAX)
      base_h = 0.6 * base_w / 3 # so boxes have 1:1 ratio
      @box_w = base_w / 3 / 10
      @box_h = @box_w

      @pad = 3
      @gap = 6 + 2 * @pad

      @rects[:s] = {
        x: @control.x + base_w / 3 + @gap,
        y: @control.y,
        w: base_w / 3 + 2 * @pad,
        h: base_h + 2 * @pad,
        anchor_x: 0.5,
        anchor_y: 0.5
      }

      @rects[:m] = {
        x: @control.x,
        y: @control.y,
        w: base_w / 3 + 2 * @pad,
        h: base_h + 2 * @pad,
        anchor_x: 0.5,
        anchor_y: 0.5
      }

      @rects[:h] = {
        x: @control.x - base_w / 3 - @gap,
        y: @control.y,
        w: base_w / 3 + 2 * @pad,
        h: base_h + 2 * @pad,
        anchor_x: 0.5,
        anchor_y: 0.5
      }

      @control.w = @rects[:s].x + @rects[:s].w / 2 - (@rects[:h].x - @rects[:h].w / 2)
      @control.h = @rects[:s].h

      %i[h m s].each do |sym|
        r = Geometry.rect_props @rects[sym]
        @boxes[sym].each do |b|
          b.x = r.x + @box_w / 2 + b.col * @box_w + @pad
          b.y = r.y + @box_h / 2 + b.row * @box_h + @pad
          b.w = @box_w - @pad * 2
          b.h = @box_h - @pad * 2
        end
      end
    end

    def tick(_args)
      h, m, s = time_segments(@control.timer.elapsed())

      ts = { h: h, m: m, s: s }

      ts.each_pair do |sym, value|
        diff = value.to_i - @boxes[sym].length
        diff += 1 if sym == :s && @control.timer.running?
        if diff.positive?
          # add boxes
          diff.times do
            @boxes[sym] << {
              created_at: Kernel.tick_count,
              anchor_x: 0.5,
              anchor_y: 0.5,
              **@control.color
            }
          end
        elsif diff.negative?
          # remove boxes
          @boxes[sym] = @boxes[sym][0, value]
        end

        r = Geometry.rect_props @rects[sym]
        @boxes[sym].each_with_index do |b, i|
          if b.created_at == Kernel.tick_count
            # initialize box
            b.col = i % 10
            b.row = i.idiv(10)
            b.x = r.x + @box_w / 2 + b.col * @box_w + @pad
            b.y = r.y + @box_h / 2 + b.row * @box_h + @pad
            b.w = @box_w - @pad * 2
            b.h = @box_h - @pad * 2
          end

          b.a = @control.a * Easing.smooth_stop(start_at: b.created_at,
                                                end_at: b.created_at + 60,
                                                tick_count: Kernel.tick_count,
                                                power: 2)
        end
      end
    end

    def draw(args)
      args.outputs.borders << {
        x: @control.x,
        y: @control.y,
        w: @control.w + 4 * @pad,
        h: @control.h + 4 * @pad,
        anchor_x: 0.5,
        anchor_y: 0.5,
        **@control.color,
        a: 50
      }

      args.outputs.solids << @rects[:s].merge(**@control.color, a: 20)
      args.outputs.solids << @boxes[:s]

      args.outputs.solids << @rects[:m].merge(**@control.color, a: 20)
      args.outputs.solids << @boxes[:m]

      args.outputs.solids << @rects[:h].merge(**@control.color, a: 20)
      args.outputs.solids << @boxes[:h]
    end
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

    def tick(args); end

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
