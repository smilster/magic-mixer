# 🎵 Audio Song Processing (MP3/MP4 Compression & Tempo Stretching)

The Bash script `process-song.sh` compresses, optionally tempo-stretches audio tracks, and auto generates `config.json` for song you Magic Mixer. The **compression** is particularly advised if you only have your audio tracks stored in huge `.wav` files. The **time-stretching** is useful to slow down (or speed up) your audio in much higher-quality than what the real-time tempo changer in the Magic Mixer will do. In fact, `process-song.sh` can also just be used to create a default `config.json`. 



### For Compressing an

-   ffmpeg
-   ffprobe
-   jq
-   rubberband-cli
-   bc

s