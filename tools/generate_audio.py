"""Generate original Blackbriar audio. Python standard library; deterministic, no samples."""
import math, random, struct, wave
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1] / 'assets'
RATE = 22050
TAU = math.tau

def save(name, seconds, signal):
    samples = []
    for i in range(round(seconds * RATE)):
        t = i / RATE
        value = max(-0.9, min(0.9, signal(t, i)))
        samples.append(round(value * 32767))
    with wave.open(str(ROOT / name), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(struct.pack('<' + 'h' * len(samples), *samples))

# Frequencies and all modulations make integer cycles over 12 seconds.
# Consequently phase, amplitude and their derivatives agree at the seam.
def ambient(t, i):
    base = sum(a * math.sin(TAU*f*t) for f,a in [(55,0.11),(82.5,0.035),(110,0.035),(130.8333333333333,0.019),(165,0.015)])
    breath = 0.72 + 0.12*math.cos(TAU*t/12) + 0.05*math.cos(TAU*t/6)
    shimmer = 0.012*math.sin(TAU*440*t)*(0.5-0.5*math.cos(TAU*t/12))
    return base*breath + shimmer
save('ambience.wav', 12, ambient)

def tone(t, frequency, decay):
    return math.sin(TAU*frequency*t) * math.exp(-decay*t)
def envelope(t, length):
    return min(1,t/0.006)*min(1,max(0,(length-t)/0.025))
save('click.wav',0.13,lambda t,i: envelope(t,.13)*(.15*tone(t,660,36)+.06*tone(t,990,48)))
save('play.wav',0.65,lambda t,i: envelope(t,.65)*(.13*tone(t,220,6)+.08*tone(t,330,7)+.04*tone(t,440,9)))
rng = random.Random(721)
noise = [rng.uniform(-1,1) for _ in range(RATE)]
save('clash.wav',0.52,lambda t,i: envelope(t,.52)*(.15*tone(t,82.5,12)+.09*tone(t,147,18)+.10*noise[i]*math.exp(-24*t)))
def victory(t,i):
    total=0
    for start,freq in [(0,220),(.16,261.6256),(.32,330),(.48,440)]:
        u=t-start
        if u>=0: total += min(1,u/.015)*(.085*tone(u,freq,2.5)+.02*tone(u,freq*2,4))
    return envelope(t,2.2)*total
save('victory.wav',2.2,victory)
print('Generated five original mono PCM sound assets.')
