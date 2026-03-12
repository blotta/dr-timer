require 'app/bezier'
require 'app/timer'
require 'app/controls/mode_button'
require 'app/controls/reset_button'
require 'app/controls/timer_control'

COLOR_NORMAL = { r: 200, g: 200, b: 200, a: 100 }.freeze
COLOR_HIGHLIGHT = { r: 200, g: 200, b: 200, a: 255 }.freeze
COLOR_HOVER = { r: 200, g: 200, b: 200, a: 160 }.freeze

HOLE_PUNCH_BLENDMODE = Numeric.compose_blendmode(BLENDFACTOR_ZERO,
                                                 BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                                 BLENDOPERATION_ADD,
                                                 BLENDFACTOR_ZERO,
                                                 BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                                                 BLENDOPERATION_ADD)

def tick(args)
  args.outputs.background_color = Array.new(3, 33) << 255

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

$gtk.reset
