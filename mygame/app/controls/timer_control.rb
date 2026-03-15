require_relative 'control'
require_relative 'timer_visuals/boxes_visual'
require_relative 'timer_visuals/number_text_visual'

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
    @visuals = [
      NumberTextVisual.new(self),
      BoxesVisual.new(self)
    ]
    @visuals_enum = @visuals.cycle
    @visual = @visuals_enum.next # BoxesVisual.new(self)
    @visual.update_size()
    self.color = (COLOR_NORMAL)
    calc_bezier_control_points()
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
    margin = [150, 180]
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
      if args.inputs.keyboard.ctrl
        @visual.next_mode()
      else
        @visual = @visuals_enum.next
        @visual.update_size()
        calc_bezier_control_points()
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

      over_at = @visual.point_inside_segment(args.inputs.mouse)
      return false if over_at.nil?

      if @timer.stopped?
        h, m, s = time_segments(@timer.elapsed)
        case over_at
        when :h
          h += wheel_y
          h = h.clamp_wrap(0, 59)
        when :m
          m += wheel_y
          m = m.clamp_wrap(0, 59)
        when :s
          s += wheel_y
          s = s.clamp_wrap(0, 59)
        end
        new_elapsed = (h * 60 * 60) + (m * 60) + s
        @timer.elapsed = new_elapsed
      else
        mult = { h: 3600, m: 60, s: 1 }
        add_secs = wheel_y * mult[over_at]
        @timer << add_secs
      end
      @visual.on_elapsed_changed(over_at, wheel_y)

      return true
    end
    return false
  end

  def point_inside?(p)
    return true if !@visual.point_inside_segment(p).nil?

    false
  end
end
