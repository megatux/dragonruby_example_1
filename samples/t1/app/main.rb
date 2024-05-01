class MyGame
  attr_gtk
  attr_reader :player
  alias engine args

  def initialize(engine)
    @player = Player.new(engine, engine.grid.w / 2, engine.grid.h / 2)
  end

  def tick
    handle_input
    render
    debug
  end

  private def debug
    outputs.labels << [20, 30, "DEBUG: x:#{player.x}/y:#{player.y} - running:#{player.running}"]
    outputs.labels << [20, 50, "DEBUG: source_x:#{player.source_x}/source_y:#{player.source_y}"]
    outputs.labels << [20, 70, "DEBUG: Frame idx:#{player.running ? player.running.frame_index(count: 6, repeat: true) : player.running}"]
  end

  private def handle_input
    gtk.request_quit if keyboard.key_down.escape
    player.handle_input(keyboard, args.tick_count)
  end

  private def render
    render_scenario
    outputs.sprites << player
  end

  private def render_scenario
    outputs.solids << [10, 10, 1270, 710, 190, 190, 220]

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
  end
end

class Player
  attr_sprite
  attr :running
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
    @path = "mygame/sprites/t1/punk_run.png"
  end

  def handle_input(keyboard, tick_count)
    should_update = false

    if keyboard.left
      move(:left)
      should_update = true
    end
    if keyboard.right
      move(:right)
      should_update = true
    end
    if keyboard.down
      move(:down)
      should_update = true
    end
    if keyboard.up
      move(:up)
      should_update = true
    end

    if should_update
      @running ||= tick_count
      update
    else
      stop
    end
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

  def stop
    @running = false
  end

  # Update source_x based on frame_index if currently running
  def update
    if @running
      @source_x =
        @source_w * @running.frame_index(count: 6, hold_for: 4, repeat: true)
    end
  end

  def no_collision
    true
  end
end

# ----------------- MAIN ----------------------
def tick(engine)
  $my_game ||= MyGame.new(engine)
  $my_game.args = engine
  $my_game.tick
end
