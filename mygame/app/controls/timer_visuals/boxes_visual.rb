class TimerControl < Control
  class BoxesVisual
    WIDTH_MIN = Grid.w * 0.5
    WIDTH_MAX = Grid.w * 0.8

    def initialize(control)
      @control = control
      @rects = {}
      @boxes = { s: [], m: [], h: [] }
      @ms_box = {
        moved_at: Kernel.tick_count,
        col: 1,
        row: 1,
        x: 0,
        y: 0,
        w: @box_w,
        h: @box_h,
        anchor_x: 0.5,
        anchor_y: 0.5,
        **@control.color
      }
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

      r = Geometry.rect_props @rects[:s]
      @ms_box.x = r.x + @box_w / 2 + @ms_box.col * @box_w + @pad
      @ms_box.y = r.y + @box_h / 2 + @ms_box.row * @box_h + @pad
      @ms_box.w = @box_w - @pad * 2
      @ms_box.h = @box_h - @pad * 2
    end

    def tick(_args)
      h, m, s = time_segments(@control.timer.elapsed())
      ms = s - s.floor

      ts = { h: h, m: m, s: s }

      ts.each_pair do |sym, value|
        diff = value.to_i - @boxes[sym].length
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
          b.a = @control.a
        end

        # milliseconds
        r = Geometry.rect_props @rects[:s]
        i = @boxes[:s].length
        @ms_box.col = i % 10
        @ms_box.row = i.idiv(10)
        @ms_box.x = r.x + @box_w / 2 + @ms_box.col * @box_w + @pad
        @ms_box.y = r.y + @box_h / 2 + @ms_box.row * @box_h + @pad
        @ms_box.a = @control.a * 0.8 * Easing.smooth_start(start_at: 0,
                                                           end_at: 60,
                                                           tick_count: ms * 60,
                                                           power: 2)
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
      args.outputs.solids << @ms_box

      args.outputs.solids << @rects[:m].merge(**@control.color, a: 20)
      args.outputs.solids << @boxes[:m]

      args.outputs.solids << @rects[:h].merge(**@control.color, a: 20)
      args.outputs.solids << @boxes[:h]
    end

    def point_inside_segment(p)
      return :s if p.inside_rect? @rects[:s]
      return :m if p.inside_rect? @rects[:m]
      return :h if p.inside_rect? @rects[:h]
    end

    def point_inside_seconds?(p)
      p.inside_rect? @rects[:s]
    end

    def point_inside_minutes?(p)
      p.inside_rect? @rects[:m]
    end

    def point_inside_hours?(p)
      p.inside_rect? @rects[:h]
    end

    def on_elapsed_changed(segment, amount); end
  end
end
