class Ball < Sprite
  COLORS = [
    [246, 255, 153],
    [159, 255, 239],
    [217, 164, 254],
    [254, 198, 170],
    [175, 253, 182],
    [180, 193, 253],
    [253, 186, 214],
    [232, 253, 191],
    [196, 248, 253],
    [255, 127, 127],
  ]

  attr_reader :lv # level

  def initialize(x, y, img, lv, observers)
    super(x, y, img)
    @lv = lv
    @observers = observers
  end

  def self.create(x, y, radius, lv, angle, observers)
    w = radius * 2

    img = create_image(lv, w)

    ball = Ball.new(x, y, img, lv, observers)
    ball.angle = angle
    ball.physical_body = [:rectangle, w, w, `{restitution: 0.9}`]
    ball
  end

  def self.create_image(lv, w, opacity = 255)
    color = lv_to_color(lv, opacity)
    img = Image.new(w, w, color)
    img.box(0, 0, w - 1, w - 1, [opacity, 0, 0, 0])
    img.draw_font(2, 2, "#{lv}", FONT_BALL, [opacity, 0, 0, 0])
    img
  end

  def self.lv_to_color(lv, opacity = 255)
    rgb = COLORS[lv - 1] || [255, 255, 0]
    [opacity, *rgb]
  end

  def hit(offence)
    # puts "hit #{self} <= #{offence}"
    if @lv == offence.lv
      if @lv <= (Game::LV_MAX - 1)
        @observers.each { |observer|
          observer.on_hit(self, offence)
        }
      end
    end
  end
end
