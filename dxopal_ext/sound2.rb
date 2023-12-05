# forked from DXOpal v1.5.2
# https://github.com/yhara/dxopal/tree/v1.5.2

require 'dxopal/remote_resource'

module DXOpal
  class Sound2 < RemoteResource
    RemoteResource.add_class(Sound2)

    # 0..255
    @@master_volume = 230

    # Return AudioContext
    def self.audio_context
      @@audio_context ||= %x{
        new (window.AudioContext||window.webkitAudioContext)
      }
    end

    # Load remote sound (called via Window.load_resources)
    def self._load(path_or_url)
      snd = new(path_or_url)
      snd_promise = %x{
        new Promise(function(resolve, reject) {
          var request = new XMLHttpRequest();
          request.open('GET', #{path_or_url}, true);
          request.responseType = 'arraybuffer';
          request.onload = function() {
            var audioData = request.response;
            var context = #{Sound2.audio_context};
            context.decodeAudioData(audioData, function(decoded) {
              snd['$decoded='](decoded);
              resolve();
            });
          };
          request.send();
        });
      }
      return snd, snd_promise
    end

    def initialize(path_or_url)
      @path_or_url = path_or_url  # Used in error message
      @volume = 230
    end
    attr_accessor :decoded

    def set_volume(volume, time=0)
      # TODO Support time
      @volume = volume
    end

    def self.master_volume=(volume)
      @@master_volume = volume
    end

    # def gain_value
    #   (@volume.to_f / 255.0) ** 10
    # end

    def gain_value
      v_ratio = @volume / 255.0
      mv_ratio = @@master_volume / 255.0
      (v_ratio * mv_ratio) ** 10
    end

    # Play this sound once
    def play
      raise "Sound2 #{path_or_url} is not loaded yet" unless @decoded
      source = nil
      %x{
        var context = #{Sound2.audio_context};
        source = context.createBufferSource();
        source.buffer = #{@decoded};

        // source.connect(context.destination);

        var gain = context.createGain();
        gain.gain.value = #{gain_value};
        source.connect(gain);
        gain.connect(context.destination);

        source.start(0); 
      }
      @source = source
    end

    # Stop playing this sound (if playing)
    def stop
      return unless @decoded 
      return unless @source
      @source.JS.stop()
    end
  end
end
