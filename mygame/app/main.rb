class MyGame
  attr_gtk
  attr_reader :player

  def initialize(engine)
    @args = engine

    state.screen = :start
    state.debug_on = false
    state.game_paused = false
    @score = @hiscore = 0

    # Entities
    @player = Player.new(@args, @args.grid.w / 2, @args.grid.h / 2)
    @big_fire = BigFire.new(@args, 200, 200)
    @floor_fires = new_fires
    @coin = new_coin
  end

  def new_coin
    coin_pos = rand_xy
    Coin.new(@args, coin_pos[0], coin_pos[1])
  end

  def new_fires
    50.times.map do |i|
      xy = rand_xy
      FloorFire.new(@args, xy[0], xy[1])
    end
  end

  def tick(args)
    @args = args

    if state.screen == :start
      handle_start_input
      render_start_screen
    else
      handle_input
      render_ingame
    end
  end

  private

  def handle_input
    gtk.request_quit if keyboard.key_down.escape
    state.debug_on = !state.debug_on if keyboard.key_up.x

    state.game_paused = !args.inputs.keyboard.has_focus

    player.handle_input(keyboard, inputs.controller_one, args.tick_count)
  end

  def handle_start_input
    gtk.request_quit if keyboard.key_down.escape
    state.screen = :ingame if keyboard.enter || inputs.controller_one.start
  end

  def render_ingame
    draw_statics unless state.statics_drawed

    render_scenario

    if state.game_paused
      render_pause
    else
      render_entities

      if coin_picked?
        outputs.labels << [700, 400, "COIN!"] if state.debug_on
        @score += 1
        @hiscore = @score if @score > @hiscore
        audio[:collected] ||= { input: "sounds/collected.wav" }
        @coin = new_coin
      end

      if collision?
        outputs.labels << [400, 400, "COLLISION"] if state.debug_on
        player_hit
        if player.death?
          state.screen = :start
          @score = 0
          @floor_fires = new_fires
          @player = Player.new(@args, @args.grid.w / 2, @args.grid.h / 2)
        end
      end
    end

    show_debug_data if state.debug_on
  end

  def render_start_screen
    draw_statics unless state.statics_drawed
    audio[:start] ||= { input: "sounds/fire.wav", gain: 0.2 }

    outputs.solids << [10, 10, 1270, 710, 210, 15, 28]
    outputs.labels << [(grid.w / 2) - 10, (grid.h / 2) + 70, "---THE FIRE---"]
    outputs.labels << [(grid.w / 2) - 80, grid.h / 2, "PRESS ENTER OR START TO BEGIN"]
    outputs.labels << [600, 708, "HiScore: #{@hiscore}"]
    @big_fire.update(tick_count)
    outputs.sprites << @big_fire
  end

  def show_debug_data
    outputs.borders << [15, 11, 500, 65]
    outputs.labels << [20, 30, "DEBUG: x:#{player.x}/y:#{player.y} - running:#{player.running}"]
    outputs.labels << [20, 50, "DEBUG: source_x:#{player.source_x}/source_y:#{player.source_y}"]
    outputs.labels << [20, 70, "DEBUG: #{@coin.collision_rect}"]

    outputs.borders << player.collision_rect
    @floor_fires.each do |f|
      outputs.borders << f.collision_rect
    end
    outputs.borders << @coin.collision_rect
  end

  def render_entities
    outputs.sprites << player

    @floor_fires.each do |fire|
      fire.update
      outputs.sprites << fire
    end
    @coin.update(tick_count)
    outputs.sprites << @coin
  end

  def rand_xy
    x = rand(1200) + 30
    y = rand(700)

    while (x - @player.x).abs < 30 && (y - @player.y).abs < 30
      x = rand(1200) + 30
      y = rand(700) + 20
    end
    [x, y]
  end

  def render_pause
    outputs.labels << [grid.w / 2, grid.h / 2, "GAME PAUSED"]
  end

  def render_scenario
    outputs.solids << [10, 10, 1270, 710, 89, 215, 88]

    @player.lives.times do |l|
      outputs.labels << [10, 708, "Score: #{@score}"]
      outputs.labels << [500, 708, "HiScore: #{@hiscore}"]
      outputs.labels << [210, 708, "Lives:"]
      outputs.solids << { x: 280 + (l*20), y: 690, w: 15, h: 15, r: 200, g: 0, b: 0 }
    end
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

  def collision?
    @floor_fires.any? do |f|
      f.collision_rect.intersect_rect?(player.collision_rect)
    end
  end

  def coin_picked?
    @coin.collision_rect.intersect_rect?(player.collision_rect)
  end

  def player_hit
    if !audio[:hit]
      player.hit
      audio[:hit] ||= { input: "sounds/explode.wav" }
    end
  end
end

class Player
  attr_sprite
  attr_reader :running, :x, :y, :w, :real_w, :h, :real_h, :source_x, :source_y, :lives

  def initialize(engine, x, y)
    @engine = engine
    @lives = 5
    @x = x
    @y = y

    @w = 48
    @real_w = 25
    @h = 48
    @real_h = 38

    @source_x = 0
    @source_y = 0
    @source_w = @w
    @source_h = @h
    @running = false
    @path_run = "sprites/punk_run.png"
    @path_idle = "sprites/punk_idle.png"
    @path = @path_run
    @flip_horizontally = false
  end

  def collision_rect
    { x: @flip_horizontally ? x + 22 : x, y: y - 2, w: real_w, h: real_h }
  end

  def handle_input(keyboard, controller, tick_count)
    should_run = false

    if keyboard.left || controller.left
      move(:left)
      should_run = true
      @flip_horizontally = true
    end

    if keyboard.right || controller.right
      move(:right)
      should_run = true
      @flip_horizontally = false
    end

    if keyboard.down || controller.down
      move(:down)
      should_run = true
    end

    if keyboard.up || controller.up
      move(:up)
      should_run = true
    end

    @running ||= tick_count
    update_character_animation(should_run)
  end

  def move(direction)
    case direction
    when :left
      @x -= 5 if x > -10 && no_collision
    when :right
      @x += 5 if x < (Grid.allscreen_w - @w) && no_collision
    when :down
      @y -= 5 if y > 10 && no_collision
    when :up
      @y += 5 if y < (Grid.allscreen_h - @h) && no_collision
    end
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

  def hit
    @lives -= 1 if lives > 0
  end

  def death?
    lives <= 0
  end
end

class BigFire
  attr_sprite

  def initialize(engine, x, y)
    @engine = engine
    @x = x
    @y = y

    @w = 400
    @h = 400
    @source_x = 0
    @source_y = 0
    @source_w = @w
    @source_h = @h
    @path_base = "sprites/explosion_"
    update
  end

  def update(tick_count = 1)
    idx = ((tick_count % 6) + 1).frame_index(count: 6, hold_for: 4, repeat: true)
    @path = @path_base + (idx.to_s || "1") + ".png"
  end
end

class FloorFire
  attr_sprite

  def initialize(engine, x, y)
    @engine = engine
    @x = x
    @y = y
    @frame = rand(8)
    @frame_speed = rand(30) + 5
    @w = 24
    @h = 32
    @source_x = 0
    @source_y = 0
    @source_w = @w
    @source_h = @h
    @path = "sprites/burning_loop_1.png"
  end

  def update
    frame = @frame.frame_index(count: 8, hold_for: @frame_speed, repeat: true)
    # @engine.outputs.labels << [@x, @y + 5, frame]
    @source_x = @source_w * frame
  end

  def collision_rect
    { x: x + 2, y: y, w: w - 4, h: h - 8 }
  end
end

class Coin
  attr_sprite

  def initialize(engine, x, y)
    @engine = engine
    @x = x
    @y = y
    @w = 32
    @h = 32
    @source_x = 0
    @source_y = 0
    @source_w = @w / 2
    @source_h = @h / 2
    @path = "sprites/coin.png"
  end

  def update(tick_count)
    frame = tick_count.frame_index(count: 6, hold_for: 5, repeat: true)
    @source_x = @source_w * 1.frame_index(count: 6, hold_for: 5, repeat: true)
  end

  def collision_rect
    { x: x + 2, y: y, w: w, h: h }
  end
end
# ----------------- MAIN ----------------------
def tick(engine)
  $my_game ||= MyGame.new(engine)
  $my_game.tick(engine)
end
