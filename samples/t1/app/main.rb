# frozen_string_literal: true

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

    outputs.labels << [20, 30, "DEBUG: x:#{player.x}/y:#{player.y} - running:#{player.running} key:#{keyboard.active}" ]
  end

  def handle_input
    player.move(:left) if keyboard.left
    player.move(:right) if keyboard.right
    player.move(:down) if keyboard.down
    player.move(:up) if keyboard.up

    gtk.request_quit if keyboard.key_down.escape
  end

  def render
    outputs.sprites << player
    render_bg
    render_borders
  end

  def render_bg
    #output
  end

  def render_borders
    outputs.static_solids << { x: 0,
                              y: 0,
                              w: Grid.allscreen_w,
                              h: 10,
                              r: 40,
                              g: 80,
                              b: 90 }
    outputs.static_solids << { x: 0,
                               y: Grid.allscreen_h - 10,
                               w: Grid.allscreen_w,
                               h: 10,
                               r: 40,
                               g: 80,
                               b: 10 }
    outputs.static_solids << { x: 0,
                               y: 0,
                               w: 10,
                               h: Grid.allscreen_h - 10,
                               r: 10,
                               g: 20,
                               b: 90 }
    outputs.static_solids << { x: Grid.allscreen_w - 10,
                               y: 0,
                               w: 10,
                               h: Grid.allscreen_h - 10,
                               r: 40,
                               g: 80,
                               b: 90 }
  end
end

class Player
  attr_sprite
  attr_reader :running, :x, :y

  def initialize(engine, x, y)
    @engine = engine
    @x = x
    @y = y
    @w = 20
    @h = 20
    @path = "mygame/sprites/t1/character.png"
  end

  def move(direction)
    case direction
    when :left
      @x -= 10 if x > 10 && no_collision
    when :right
      @x += 10 if x < 1250 && no_collision
    when :down
      @y -= 10 if y > 10 && no_collision
    when :up
      @y += 10 if y < 690 && no_collision
    end
  end

  def tick(_args)
  end

  def no_collision
    true
  end
end

# ---------------------------------------
def tick(engine)
  $my_game ||= MyGame.new(engine)
  $my_game.args = engine
  $my_game.tick
end
