class CellOrdering
  VARIANTS = %i[
    bottom_left_to_top_right
    top_left_to_bottom_right
    snake
    columns
    columns_snake
    center_out
    border_in
    random
  ].freeze

  attr_reader :width, :height, :size, :variant, :cells

  def initialize(width, height, variant = :bottom_left_to_top_right)
    @width  = width
    @height = height
    @size   = width * height

    set_variant(variant)
  end

  def set_variant(name)
    raise "Unknown variant #{name}" unless VARIANTS.include?(name)

    @variant = name
    @cells = send(name)
  end

  def next_variant
    i = VARIANTS.index(@variant)
    set_variant(VARIANTS[(i + 1) % VARIANTS.length])
  end

  private

  def bottom_left_to_top_right
    (0...size).map { |i| [i % width, i.idiv(width)] }
  end

  def top_left_to_bottom_right
    (0...size).map do |i|
      col = i % width
      row = height - 1 - i.idiv(width)
      [col, row]
    end
  end

  def snake
    (0...size).map do |i|
      col = i % width
      row = i.idiv(width)
      col = width - 1 - col if row.odd?
      [col, row]
    end
  end

  def columns
    (0...size).map do |i|
      col = i.idiv(height)
      row = i % height
      [col, row]
    end
  end

  def columns_snake
    (0...size).map do |i|
      col = i.idiv(height)
      row = i % height
      row = height - 1 - row if col.odd?
      [col, row]
    end
  end

  def center_out
    cx = (width - 1) / 2.0
    cy = (height - 1) / 2.0

    base = (0...size).map { |i| [i % width, i.idiv(width)] }

    base.sort_by { |c, r| (c - cx).abs + (r - cy).abs }
  end

  def border_in
    cx = (width - 1) / 2.0
    cy = (height - 1) / 2.0

    base = (0...size).map { |i| [i % width, i.idiv(width)] }

    base.sort_by { |c, r| -((c - cx).abs + (r - cy).abs) }
  end

  def random
    base = (0...size).map { |i| [i % width, i.idiv(width)] }
    base.shuffle
  end
end
