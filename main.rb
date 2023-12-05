require "dxopal"
require_relative "dxopal_ext/sound2"
require_relative "dxopal_ext/sound_effect2"
include DXOpal

require_relative "ball"
require_relative "game"

WIN_W = 640
WIN_H = 480

FONT_DEFAULT    = Font.new(20, "monospace")
FONT_BALL       = Font.new(16, "monospace")
FONT_GAMEOVER   = Font.new(80, "monospace")
FONT_DEBUG_INFO = Font.new(12, "monospace")

def pre_tick
  if (
      (Input.key_down?(K_LCONTROL) && Input.key_push?(K_R)) ||
      (Input.key_down?(K_RCONTROL) && Input.key_push?(K_R)) ||
      Input.key_push?(K_F5)
    )
    `location.reload()`
  end
end

# vol: 0..255
def set_master_volume(vol, play = false)
  Sound2.master_volume = vol

  if play
    SoundEffect2["lv1"].play
  end
end

# --------------------------------
# sound

SoundEffect2.register(:s1, 50, WAVE_TRI, 1000) do
  [1000, 120]
end

SoundEffect2.register(:hit3_long, 300, WAVE_SAW, 1000) do
  [50, 100]
end

NOTE_NOS = [
  0,  # c4
  7,  # g4
  11, # b4
  2,  # d4
  5,  # f4

  12, # c5
  19, # g5
  23, # b5
  14, # d5
  17, # f5
]

def create_sound_ball_new(lv)
  duration_msec = 500
  note_i = lv - 9
  note_no = NOTE_NOS[note_i]
  base_freq = (440 * (2 ** (note_no / 12.0))).to_f
  msec = 0

  SoundEffect2.register("lv#{lv}", duration_msec, WAVE_TRI) {
    vol =
      if msec < 100
        20
      elsif msec < 200
        1
      elsif msec < 300
        5
      elsif msec < 400
        1
      else
        2
      end
    vol = vol * (255.0 / 20)

    freq =
      if msec < 20
        base_freq / 2
      else
        base_freq
      end

    msec += 1

    [freq, vol]
  }
end

(1..Game::LV_MAX).each{ |lv|
  create_sound_ball_new(lv)
}

# --------------------------------

Window.width  = WIN_W
Window.height = WIN_H
Window.fps = 60
Window.bgcolor = [250, 250, 250]

set_master_volume(230)

$game = Game.new
$game.init_basket()

Window.load_resources do
  puts "load_resources ... done"

  Window.loop do
    pre_tick
    $game.tick
  end
end
