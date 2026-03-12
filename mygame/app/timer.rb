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
    return unless running? # && Kernel.tick_count.zmod?(30)

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
