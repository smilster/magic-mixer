# Song Processor

The `song-processor` utilities support you with the setting up your Magic Mixer:

- Compress audio files  
- Stretch tracks to target tempo
- Optimized for multi-track playback and fast downloads
- Autogenerate song configs compatible with the Magic Mixer

They consist of the following Bash scripts: `create_default_config.sh`, `stretch_and_compress.sh`. and `update_index_html.sh`.

The **compression** is particularly advised if you only have your audio tracks stored in huge `.wav` files. The **time stretching** is useful to slow down (or speed up) your audio (while preserving the pitch) in much higher-quality than what the real-time tempo changer in the Magic Mixer will do.

### Requirements
Brackets denote versions the script was tested with. It should work with lower versions as well, as conservative syntax and commands were used.

- bash (5.3.9)
- awk (5.4.6)
- sed (4.10)
- jq (1.8.1-dirty)
- ffmpeg (8.1.1)
- rubberband (4.0.0)

### `create_default_config.sh`

| flag              | description                                                           |
|-------------------|-----------------------------------------------------------------------|
| `--songId`        | song id / directory in `songs`                                        |
| `--bpm`           | beats per minute of recorded song                                     |
| `--timeSignature` | time signature of your song (signature changes are not supported yet) |
| `--file_format`   | output audio format for compressed songs                              |
| `--masterGain`    | NOT implemented, will be ignored, adjust manually in `config.json`    |
| `--startMeasure`  | NOT implemented, will be ignored, adjust manually in `config.json`    |
| `--title`         | NOT implemented, will be ignored, adjust manually in `config.json`    |


You just exported synchronous audio files and placed them in the `songs` folder. The Magic Mixer needs the song config, `config.json`, to work, and this script will set up your song with default song and track properties. So let's assume your file structure looks like this:
```
└── songs
|   ├── newSong
|   │   ├── vocals.wav
|   │   ├── guitar.wav
|   │   └── drums.wav
```

Just execute, for example, 

```bash
create_default_config.sh \
--songId newSong \
--bpm 92 \
--timeSignature 4/4
```
 and `config.json` inside `newSong` will be created automatically. You may then adjust values as needed. Note that `--bpm` and `--timeSignature` are required for the Magic Mixer to display transport position correctly. So after execution, you will see
```
└── songs
|   ├── newSong
|   │   ├── vocals.wav
|   │   ├── guitar.wav
|   │   ├── drums.wav
|   │   └── config.json
```



### `stretch_and_compress.sh`

| flag              | description                                                           |
|-------------------|-----------------------------------------------------------------------|
| `--songId`        | song id / directory in `songs`                                        |
| `--bpm`           | beats per minute of recorded song                                     |
| `--timeSignature` | time signature of your song (signature changes are not supported yet) |
|                   |                                                                       |

#### Compressing

Exporting your tracks with your DAW at the highest possible quality is absolutely reasonable. However, you want your Magic Mixer to load as fast as possible and to be available even in areas with poor connections. In fact, the crisp of your recordings will not play any role for rehearsal. It's more about availability and convenience. So, compress your track audios to a very low level, or let  `stretch_and_compress.sh` do the work for you.

Assuming you have a file structure like in the previous example (huge uncompressed `.wav` files), which may be even 100MB and more depending on track number and song length. Let `stretch_and_compress.sh` compress your audio to mp3 or mp4 format, and squeeze it down to a few MB:

```bash
stretch_and_compress.sh \
--songId newSong \
--bpm 92 \
--timeSignature 4/4
```

This script leaves the original folder untouched, and only copies the song and track properties if a `config.json` exists already. So after execution of the above command, new folders will be created: One with a copy of the raw audio but including a `config.json`, and one with compressed audio (`.mp3` in this case)

```
├── songs
│   ├── newSong
│   │   ├── drums.wav
│   │   ├── guitar.wav
│   │   ├── vocals.wav
│   │   └── config.josn 
│   ├── newSong-92-bpm
│   │   ├── config.json
│   │   ├── drums.wav
│   │   ├── guitar.wav
│   │   └── vocals.wav
│   ├── newSong-92-bpm-mp3
│   │   ├── config.json
│   │   ├── drums.mp3
│   │   ├── guitar.mp3
│   │   └── vocals.mp3
```

The directories with the `config.json` can be imported by the Magic Mixer and at the end, the script will provide you with a HTML example, e.g.

```html
<div id="magic-mixer">
    <song>newSong-92-bpm</song>
    <song>newSong-92-bpm-mp3</song>
</div>
```

#### Strech Tempo and Compress

Although the Magic Mixer allows for real-time tempo adjustment through granular synthesis, the acceptable quality of the granular stretching is limited to only a few percent (~20%). If you want to slow down by, e.g., half the tempo in high quality, you can either use your DAW, or employ `rubberband`. The script `stretch_and_compress.sh` will automate this process for you by providing target BPMs via `--target_bpm`. For example, execute 

```bash
song-processor/stretch_and_compress.sh \
--songId newSong \ 
--target_bpm 50 80
```
and the script will first stretch the original audio to the target BPMs (e.g. 50 and 80),  then compress it, and generate `config.json` files, which again will inherit properties if a config is provided in the original folder (`newSong` in this case). Note that the time stretcing performed by rubberband may take some minutes.

Now, your folder structure should look as follows  
```
├── songs
│   ├── newSong
│   ├── newSong-50-bpm
│   ├── newSong-50-bpm-mp3
│   ├── newSong-80-bpm
│   ├── newSong-80-bpm-mp3
│   ├── newSong-92-bpm
│   ├── newSong-92-bpm-mp3
```
and the script will provide you with an HTML example for usage in the `index.html`:
```html
<div id="magic-mixer">
    <song>newSong</song>
    <song>newSong-50-bpm</song>
    <song>newSong-50-bpm-mp3</song>
    <song>newSong-80-bpm</song>
    <song>newSong-80-bpm-mp3</song>
    <song>newSong-92-bpm</song>
    <song>newSong-92-bpm-mp3</song>
</div>
```

Note that the uncompressed, stretched songs (e.g. `newSong-50-bpm`) are kept in case you would like to try another audio format in the future. It will then only compress the raw, stretched files instead of stretching again. Just because compressing is much faster than stretching.

### `update_index_html.sh`

Use this tool with care! It will modify `index.html` directly.

The script `update_index_html.sh` inspects all folders in the `songs` directory and if `config.json` is found, it will list the song in `index.html` as, e.g., `<song>example-song-with-config</song>`. The script takes an unlimmeted amount of arguments, each acting as a filter, all combined with logical ANDs. So, based on the example above, the command

```bash
/update_index_html.sh mp3  
```

will manipulate your `index.html` in a way that the `magic-mixer` element will look like this:
```html
<div id="magic-mixer">
    <song>newSong-50-bpm-mp3</song>
    <song>newSong-80-bpm-mp3</song>
    <song>newSong-92-bpm-mp3</song>
</div>
```
And combining two arguments, e.g., 
```bash
update_index_html.sh mp3 80
```

will reduce to
```html
<div id="magic-mixer">
    <song>newSong-80-bpm</song>
</div>
```







