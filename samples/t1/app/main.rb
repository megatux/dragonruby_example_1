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
    render_borders
  end

  def render_borders
    outputs.solids << { x: 0,
                        y: 0,
                        w: 1280,
                        h: 10,
                        r: 40,
                        g: 80,
                        b: 90 }
    outputs.solids << { x: 0,
                        y: 710,
                        w: 1280,
                        h: 10,
                        r: 40,
                        g: 80,
                        b: 10 }
    outputs.solids << { x: 0,
                        y: 0,
                        w: 10,
                        h: 710,
                        r: 10,
                        g: 20,
                        b: 90 }
    outputs.solids << { x: 1270,
                        y: 0,
                        w: 10,
                        h: 710,
                        r: 40,
                        g: 80,
                        b: 90 }
  end
end

class Player
  attr_sprite

  def initialize(engine, x, y)
    @engine = engine
    @x = x
    @y = y
    @w = 20
    @h = 20
    @path = 'mygame/sprites/misc/star.png'
  end

  def move(direction)
    if direction == :left
      @x -= 10 if x > 10
    elsif direction == :right
      @x += 10 if x < 1250
    elsif direction == :down
      @y -= 10 if y > 10
    elsif direction == :up
      @y += 10 if y < 690
    end
  end

  def tick args
    @angle = @engine.tick_count
  end
end

# ---------------------------------------
def tick engine
  $my_game ||= MyGame.new(engine)
  $my_game.args = engine
  $my_game.tick
end
