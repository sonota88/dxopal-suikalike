class Game
  BASKET_X_MIN = 150
  BASKET_X_MAX = 640 - 150 - 40
  BASKET_W = BASKET_X_MAX - BASKET_X_MIN

  BASKET_Y_MIN = 100
  BASKET_Y_MAX = 440
  BASKET_H = BASKET_Y_MAX - BASKET_Y_MIN

  LV_MAX = 10

  MAP_LV_SCORE = {
    1  => 1,
    2  => 2,
    3  => 5,
    4  => 10,
    5  => 15,
    6  => 20,
    7  => 50,
    8  => 100,
    9  => 200,
    10 => 500,
  }

  def initialize
    @basket_floor = nil
    @basket_wall_l = nil
    @basket_wall_r = nil

    @balls = []
    @collision_list = []
    update_next_lv()

    @scene = :main

    @next_lv = 1
    @next_next_lv = 1
    @next_angle = rand() * 90

    @t_gameover_started_at = Time.now

    @auto_drop = false

    reset()
  end

  def reset
    @balls.each{ |ball| ball.vanish }
    clean_balls(@balls)
    @score = 0
    @t_next_auto_drop = Time.now + 1
  end

  def init_basket
    @basket_floor = make_wall(
      BASKET_X_MIN, BASKET_Y_MAX,
      300, 40
    )
    @basket_wall_l = make_wall(
      BASKET_X_MIN - 40, 100,
      40, BASKET_Y_MAX + 40
    )
    @basket_wall_r = make_wall(
      BASKET_X_MAX, 100,
      40, BASKET_Y_MAX + 40
    )
  end

  def set_auto_drop(auto)
    @t_next_auto_drop = Time.now + 1
    @auto_drop = auto
    SoundEffect2[:s1].play
  end

  def clean_balls(balls)
    balls
      .select{ |ball| ball.vanished? }
      .each{ |ball| ball.remove_matter_body() }
    Sprite.clean(balls)
  end

  def draw_gameover
    x = 130
    y = 160

    Window.draw_box_fill(0,0,WIN_W, WIN_H, [80, 0, 0, 0])

    Window.draw_font(x, y, "GAME OVER", FONT_GAMEOVER, { color: C_WHITE })
    y += 80

    Window.draw_font(x, y, "SCORE: #{@score}", FONT_GAMEOVER, { color: C_WHITE })
    y += 100

    if @t_gameover_started_at + 2 < Time.now
      Window.draw_font(x, y, "click to start", FONT_DEFAULT, { color: C_WHITE })
    end
  end

  def draw_next_cursor(dx)
    next_rad = Game.to_radius(@next_lv)
    circle_rad = Math.sqrt((next_rad ** 2) * 2)

    next_color = Ball.lv_to_color(@next_lv, 100)
    next_img = Ball.create_image(@next_lv, next_rad * 2, 100)
    Window.draw_rot(
      dx - next_rad, 40,
      next_img,
      @next_angle,
      next_rad, next_rad # center x, y
    )

    width = circle_rad * Math.cos((90 - (@next_angle + 45)) * (Math::PI / 180.0))

    [dx - width, dx + width].each{ |x|
      Window.draw_line(
        x, 0,
        x, WIN_H,
        [100, 0, 0, 0]
      )
    }
  end

  def draw_debug_info(y_max)
      [
        "@balls.size #{@balls.size}",
        "@collision_list.size #{@collision_list.size}",
        "@next_lv #{@next_lv}",
        "@next_next_lv #{@next_next_lv}",
        format("y max %.2f", y_max),
        "@scene #{@scene}",
      ].each_with_index{ |line, i|
        Window.draw_font(
          2, i * 20 + 40,
          line,
          FONT_DEBUG_INFO, { color: [120, 0, 0, 0] }
        )
      }
  end

  def draw_basket
    @basket_floor.draw
    @basket_wall_l.draw
    @basket_wall_r.draw
  end

  def draw_score
    Window.draw_font(
      4, 2,
      "score: #{@score}",
      FONT_DEFAULT, { color: [200, 0, 0, 0] }
    )
  end

  def draw_next_next
    base_x = 540

    Window.draw_font(base_x - 60, 2, "next:", FONT_DEFAULT, { color: [200, 0, 0, 0] })
    next_next_rad = Game.to_radius(@next_next_lv)
    next_next_peri = next_next_rad * 2
    next_next_img = Ball.create_image(@next_next_lv, next_next_peri, 200)
    Window.draw(base_x, 4, next_next_img)
  end

  def drop_ball(dx)
    lv = @next_lv
    @balls << Ball.create(dx - next_radius, 40, next_radius, @next_lv, @next_angle, [self])
    @next_angle = rand() * 90
    update_next_lv()
    SoundEffect2["lv#{lv}"].play
  end

  def on_hit(b1, b2)
    @collision_list << [b1, b2]
  end

  def tick
    mx = Input.mouse_x
    my = Input.mouse_y
    dx = to_drop_x(mx)

    if Input.mouse_push?(M_LBUTTON)
      if 0 <= my && my < WIN_H
        case @scene
        when :main
            drop_ball(dx)
        when :gameover
          if @t_gameover_started_at + 2 < Time.now
            SoundEffect2[:s1].play
            reset()
            @scene = :main
          end
        end
      end
    end

    if @scene == :main
      if @auto_drop
        if @t_next_auto_drop < Time.now
          drop_ball(dx)
          @t_next_auto_drop = Time.now + rand(5) + 0.5
        end
      end
    end

    # 衝突判定

    @collision_list = []
    @balls.each{ |ball_self|
      # 衝突した場合 @collision_list に追加される
      Sprite.check([ball_self], @balls - [ball_self])
    }

    new_balls = [] # 衝突によって新たに生成されるもの
    @collision_list.each{ |b1, b2|
      if (!b1.vanished?) && (!b2.vanished?)
        b1.vanish
        b2.vanish
        midx = (b1.x + b2.x) / 2.0
        midy = (b1.y + b2.y) / 2.0
        new_lv = b1.lv + 1
        new_balls << [new_lv, midx, midy]
        @score += MAP_LV_SCORE[new_lv]
      end
    }

    lvs = new_balls.map{ |lv, _, _| lv }.uniq
    lvs.each{ |lv|
      SoundEffect2["lv#{lv}"].play
    }

    clean_balls(@balls)

    @balls += new_balls.map{ |lv, x, y|
      rad = Game.to_radius(lv)
      angle = rand() * 90
      Ball.create(x, y, rad, lv, angle, [self])
    }

    # draw

    draw_basket()
    draw_score()
    draw_next_next()
    # draw_debug_info(y_max)

    @balls.each{ |ball| ball.draw }

    if @scene == :main
      if 0 <= my && my < WIN_H
        draw_next_cursor(dx)
      end
    end

    if @scene == :gameover
      draw_gameover()
    end

    # ゲームオーバー判定

    y_max = @balls.map{ |ball| ball.y }.max || 0

    if y_max > WIN_H + 100
      @balls
        .select{ |ball| ball.y > WIN_H + 100 }
        .each{ |ball| ball.vanish }
      clean_balls(@balls)

      SoundEffect2[:hit3_long].play

      if @scene == :main
        @t_gameover_started_at = Time.now
        @scene = :gameover
      end
    end
  end

  NEXT_LVS = [
    (1..3).to_a,
    (1..3).to_a,
    4 # 少し低い確率にする
  ].flatten

  def update_next_lv
    @next_lv = @next_next_lv
    @next_next_lv = NEXT_LVS.sample
  end

  def next_radius
    Game.to_radius(@next_lv)
  end

  def self.to_radius(lv)
    lv * 7.5 + 4
  end

  def to_drop_x(x)
    if x < BASKET_X_MIN + 2
      BASKET_X_MIN + 2
    elsif x > BASKET_X_MAX - 2
      BASKET_X_MAX - 2
    else
      x
    end
  end

  def make_wall(x, y, w, h)
    wall = Sprite.new(
        x, y,
        Image.new(w, h, [200, 200, 200])
      )
    wall.physical_body = [:rectangle, w, h, `{isStatic: true}`]
    wall
  end
end
