class TimerControl < Control
  class NumberTextVisual
    SIZE_PX_MIN = 90
    SIZE_PX_MAX = 200

    def initialize(control)
      @control = control
      @font = 'fonts/Sono-Regular.ttf'
      update_size()
      @indicators = []
    end

    def update_size
      @size_px = @control.size_perc.remap(0, 1, SIZE_PX_MIN, SIZE_PX_MAX)
      @control.w, @control.h = GTK.calcstringbox(
        format_time(0),
        size_px: @size_px, font: @font
      )
    end

    def tick(_args)
      @indicators.each do |ind|
        ind.y += ind.dir * 5
        ind.a -= 30
      end
      @indicators.reject! do |ind|
        ind.a <= 0
      end
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

      args.outputs.solids << @indicators
    end

    # returns :s | :m | :h | nil
    def point_inside_segment(p)
      offset = p.x - (@control.x - @control.w / 2)
      over_at = 2 - (offset / (@control.w / 3)).floor # h -> 2, m -> 1, s -> 0
      return :s if over_at == 0
      return :m if over_at == 1
      return :h if over_at == 2

      nil
    end

    def point_inside_seconds?(p)
      point_inside_segment(p) == :s
    end

    def point_inside_minutes?(p)
      point_inside_segment(p) == :m
    end

    def point_inside_hours?(p)
      point_inside_segment(p) == :h
    end

    def on_elapsed_changed(segment, amount)
      dir = (amount / amount.abs)
      over = { h: -1, m: 0, s: 1 }[segment]
      x = @control.x + @control.w * (over * 0.38)
      y = @control.y + dir * @control.h / 2
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
  end
end
