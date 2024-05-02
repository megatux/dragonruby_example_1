class MyGame
  attr_gtk
  attr_reader :player

  def initialize(engine)
    @args = engine
    @player = Player.new(@args, @args.grid.w / 2, @args.grid.h / 2)
    @args.state.debug_on = false
    @args.state.game_paused = false
  end

  def tick(args)
    @args = args
    handle_input
    render
  end

  private

  def handle_input
    gtk.request_quit if keyboard.key_down.escape
    state.debug_on = !state.debug_on if keyboard.key_up.x

    state.game_paused = !args.inputs.keyboard.has_focus

    player.handle_input(keyboard, args.tick_count)
  end

  def render
    draw_statics unless state.statics_drawed
    render_scenario
    state.game_paused ? render_pause : render_entities
    show_debug_data if state.debug_on
  end

  def show_debug_data
    outputs.borders << [15, 11, 500, 65]
    outputs.labels << [20, 30, "DEBUG: x:#{player.x}/y:#{player.y} - running:#{player.running}"]
    outputs.labels << [20, 50, "DEBUG: source_x:#{player.source_x}/source_y:#{player.source_y}"]
    outputs.labels << [20, 70, "DEBUG: Frame idx:#{player.running ? player.running.frame_index(count: 6, repeat: true) : player.running}"]
  end

  def render_entities
    outputs.sprites << player
  end

  def render_pause
    outputs.labels << [grid.w / 2, grid.h / 2, "GAME PAUSED"]
  end

  def render_scenario
    outputs.solids << [10, 10, 1270, 710, 209, 165, 138]
  end

  def draw_statics
    outputs.static_solids << { x: 0, y: 0,
                               w: Grid.allscreen_w, h: 10,
                               r: 40, g: 80, b: 90 }
    outputs.static_solids << { x: 0, y: Grid.allscreen_h - 10,
                               w: Grid.allscreen_w, h: 10,
                               r: 40, g: 80, b: 10 }
    outputs.static_solids << { x: 0, y: 0,
                               w: 10, h: Grid.allscreen_h - 10,
                               r: 10, g: 20, b: 90 }
    outputs.static_solids << { x: Grid.allscreen_w - 10, y: 0,
                               w: 10, h: Grid.allscreen_h - 10,
                               r: 40, g: 80, b: 90 }
    state.statics_drawed = true
  end
end

class Player
  attr_sprite
  attr_reader :running, :x, :y, :source_x, :source_y

  def initialize(engine, x, y)
    @engine = engine
    @x = x
    @y = y

    @w = 48
    @h = 48
    @source_x = 0
    @source_y = 0
    @source_w = @w
    @source_h = @h
    @running = false
    @path_run = "mygame/sprites/t1/punk_run.png"
    @path_idle = "mygame/sprites/t1/punk_idle.png"
    @path = @path_run
    @flip_horizontally = false
  end

  def handle_input(keyboard, tick_count)
    should_run = false

    if keyboard.left
      move(:left)
      should_run = true
      @flip_horizontally = true
    end
    if keyboard.right
      move(:right)
      should_run = true
      @flip_horizontally = false
    end
    if keyboard.down
      move(:down)
      should_run = true
    end
    if keyboard.up
      move(:up)
      should_run = true
    end

    @running ||= tick_count
    update_character_animation(should_run)
  end

  def move(direction)
    case direction
    when :left
      @x -= 10 if x > 10 && no_collision
    when :right
      @x += 10 if x < (Grid.allscreen_w - @w) && no_collision
    when :down
      @y -= 10 if y > 10 && no_collision
    when :up
      @y += 10 if y < (Grid.allscreen_h - @h) && no_collision
    end
  end

  def stop_running
    @running = false
  end

  # Update source_x based on frame_index if currently running
  def update_character_animation(should_run)
    @path = should_run ? @path_run : @path_idle

    @source_x = if should_run
      @source_w * @running.frame_index(count: 6, hold_for: 6, repeat: true)
    else
      @source_w * @running.frame_index(count: 4, hold_for: 12, repeat: true)
    end
  end

  def no_collision
    true
  end
end

# ----------------- MAIN ----------------------
def tick(engine)
  $my_game ||= MyGame.new(engine)
  $my_game.tick(engine)
end
