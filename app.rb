SAMPLING_RATE = `SAMPLE_RATE`
MAX_FREQ = (SAMPLING_RATE / 2) - 1

class Synth
  CYCLE_RESOLUTION  = 0x100000000
  MAX_OVERTONE      = 127
  SAMPLES_PER_CYCLE = 256

  def initialize
    @courseTune  = 64
    @fineTune    = 64
    @noteNumber  = 84
    @phase       = 0
    @freq        = 0
    @overtone    = 1

    @waveTablesSawtooth = []
    generateWaveTable(@waveTablesSawtooth, 1, lambda {|n, k|
      (2.0 / Math::PI) * Math::sin((2.0 * Math::PI) *
                                  ((n + 0.5) / SAMPLES_PER_CYCLE) * k) / k
    })
    @waveTables  = @waveTablesSawtooth

    @freqTableC4toB4 = []
    generatefreqTable

    updateFreq
  end

  def clock
    @phase += @freq
    if (@phase >= CYCLE_RESOLUTION)
      @phase -= CYCLE_RESOLUTION
    end

    x = 2;
    if (@phase >= (CYCLE_RESOLUTION - (@freq * x)))
      f = (CYCLE_RESOLUTION - @phase) / (@freq * x) - 0.5
    else
      f = @phase /(CYCLE_RESOLUTION - (@freq * x)) - 0.5
    end
    return f

    currIndex = (@phase / (CYCLE_RESOLUTION / SAMPLES_PER_CYCLE)).floor
    nextIndex = currIndex + 1
    if (nextIndex >= SAMPLES_PER_CYCLE)
      nextIndex -= SAMPLES_PER_CYCLE
    end
    waveTable = @waveTables[((@overtone + 1) / 2) - 1]
    currData = waveTable[currIndex]
    nextData = waveTable[nextIndex]

    nextWeight = @phase % (CYCLE_RESOLUTION / SAMPLES_PER_CYCLE)
    currWeight = (CYCLE_RESOLUTION / SAMPLES_PER_CYCLE) - nextWeight
    level = ((currData * currWeight) + (nextData * nextWeight)) /
            (CYCLE_RESOLUTION / SAMPLES_PER_CYCLE).to_f
  end

  private
  def generateWaveTable(waveTables, amp, f)
    (0..(((MAX_OVERTONE + 1) / 2) - 1)).each {|m|
      waveTable = []
      (0..(SAMPLES_PER_CYCLE - 1)).each {|n|
        level = 0
        (1..(m * 2)).each {|k|
          level += amp * f.call(n, k)
        }
        waveTable[n] = level
      }
      waveTables[m] = waveTable
    }
  end

  def generatefreqTable
    (0..11).each {|i|
      n = i + 60
      cent = (n * 100) - 6900
      hz = 440.0 * (2.0 ** (cent / 1200.0))
      @freqTableC4toB4[i] = hz * CYCLE_RESOLUTION / SAMPLING_RATE
    }
  end

  def updateFreq
    noteNumber = @noteNumber + @courseTune - 64
    base = (@freqTableC4toB4[noteNumber % 12] *
            (2.0 ** ((@fineTune - 64) / 768.0)) / 32).floor * 32
    @freq = base * (2.0 ** ((noteNumber / 12.0) - 5.0))
    @overtone = ((MAX_FREQ * CYCLE_RESOLUTION) / (@freq * SAMPLING_RATE)).floor
    if (@overtone > MAX_OVERTONE)
      @overtone = MAX_OVERTONE
    end
  end
end

$synth = Synth.new
