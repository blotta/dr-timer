module SpriteRT
  def make_triangle_rt(args)
    return :triangle if args.outputs.render_targets.queued?(:triangle)

    size = 200
    p1 = { x: size / 2, y: 0 }
    p2 = Geometry.rotate_point(p1, 120)
    p3 = Geometry.rotate_point(p1, 240)
    args.outputs[:triangle].w = size
    args.outputs[:triangle].h = size
    args.outputs[:triangle].background_color = [0, 0, 0, 0]
    args.outputs[:triangle].solids << {
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
      r: 255, g: 255, b: 255, a: 255
      # path: :solid
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
  module_function :make_triangle_rt

  def make_reset_btn_rt(args)
    return args.outputs.render_targets[:reset_btn].path if args.outputs.render_targets.queued?(:reset_btn)

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
  module_function :make_reset_btn_rt
end
