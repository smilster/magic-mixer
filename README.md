# Magic Mixer

**Mix - Loop - Tempo**

The **Magic Mixer** is a web-based tool for music rehearsal. It runs entirely in the browser and is designed to provide a cross-platform user interface for synchronous multi-track playback. The mixer features basic volume, pan and transport control, and allows for song selection, looping passages and changing the tempo on the fly.

The underlying audio engine, [Tone.js 15.3.5](https://tonejs.github.io/), is included in `lib/tone@15.3.5`, ensuring the Magic Mixer works independently of external sources. 

### Live Demo
https://smilster.github.io/magic-mixer

### Features

- Multi-track mixing, adjust volume, panning or mute 
- Transport control and interactive timeline 
- Loop regions by click-and-drag/swipe (timeline)
- Real-time tempo tuning
- Song selection

### planned features

- correct transport position display for songs that change timeSignature
- synthesizer click
- solo buttons
- backend build (ffmpeg, rubberband) to autogenerate songs at different tempi (better quality than GrainPlayer)
- track resolved pitch detection (sounds a bit cpu heavy though)
- add duration (bars:measure) to song selector after track has been loaded

### Magic Mixer with own songs

#### Audio File Requirements

- The tracks of the song must be perfectly synchronized. This is usually the case if you stem-exported them using a DAW.
- The audio files should stay small for fast downloading and reduced traffic. Use compressed audio files.
- If possible, use mono instead of stereo formats to further reduce file size and audio processing workload. 
- The audio file format should be widely supported, because the decoding is done on the user device. Typically, `AAC` encapsulated in, e.g., `.aac`, `.mp4` or `.m4a` files, should work. Highest support is usually guaranteed with `.mp3` files. 


#### Song Setup

 Create a directory in `songs/`. The directory name will be the unique `songId` for the Magic Mixer. Place all your audio files inside your new folder and also create `congig.js` in there.


Your folder structure  should look like this:

```tree
:
├── index.html
└── songs
|   ├── newSong
|   │   ├── config.json
|   │   ├── vocals.mp3
|   │   ├── guitar.mp3
|   │   └── drums.mp3
:
```

Add the song to your `index.html`. Look for the element with id `magic-mixer`. Each `<song>` tag will be read and its content must match the `songId` (song folder name), e.g., `newSong` in this case:


`index.html`
```html
<div id="magic-mixer">
    <song>newSong</song>
    <song load>dontStop</song>
    <song>baraye</song>
</div>
```

Note that the `load` attribute defines the song to be loaded directly on startup. If `load` is not provided, the user will only see the song selector.


The song config file ``songs/myNewSong/config.json`` stores song and track information. The minimal song setup to include tracks should look like this:

`config.json`
```json 
{
    "title": "My New Song",
    "bpm": 108,
    "timeSignature": "4/4",
    "tracks": [
      {
        "filename": "vocals.mp3"
      },
      { 
        "filename": "guitar.mp3"
      },
      { 
        "filename": "drums.mp3"
      }
    ]
}
```

#### Song Properties

| property        | default          | explanation                                                                  |
|-----------------|------------------|------------------------------------------------------------------------------|
| `title`         | song folder name | displayed in song selector                                                   |
| `bpm`           | `120`            | beats per minute during **recording**                                        |
| `timeSignature` | `"4/4"`          | time signature of your song (signature changes not supported yet)            |
| `startMeasure`  | `1`              | number of first measure as in your note sheet                                |
| `masterGain`    | `0.5`            | initial amplification of master channel , takes values between `0` and `1.5` |



Example:


`config.json`
```json 
{
    "title": "My New Song",
    "bpm": 108,
    "timeSignature": "4/4",
    "startMeasure": 0,
    "masterGain": 0.7,
    "tracks": [
      
      .
      .
      .
      
    ]
}
```


#### Track Properties


| property   | default                   | explanation                                                                                                                                                                |
|------------|---------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `filename` |                           | this field is required                                                                                                                                                     |
| `url`      |                           | custom `url` if file is stored outside `songs/` structure, `filename` will then be ignored, `url` must direct to same server or to one which support cross-origin requests |
| `label`    | generated from `filename` | displayed at the top of mixer channel                                                                                                                                      |
| `vol`      | `-15`                     | initial volume in decibels, takes values between `-30` and `6`                                                                                                             |
| `pan`      | `0`                       | initial relative panning, takes values between `-1` (100% left) and `1` (100% right)                                                                                       |
| `mute`     | `false`                   | initial mute state, either `true` or `false`                                                                                                                               |


Example:


```json 
{
    "title": "My New Song",
    "tracks": 
    [
      {
      "label": "Michael",
      "filename": "vocals.mp3",
      "pan": -0.5,
      "vol": -5
      },
      {
        "filename": "guitar.mp3",
        "pan": 5,
        "vol": -10
      },
      {
        "label": "Kick Me",
        "filename": "drums.mp3",
        "mute": true
      }
    ]
}
```


### Run Locally

If you want to run hte Magic Mixer locally, you must launch a simple server, e.g.,

`python -m RangeHTTPServer` or `python -m SimpleHTTPServer`

### Known Issues

#### Windows 10 with Edge

- might not decode m4a files -> mp3s work

#### old iPhones, Safari, Opera
- issues with vertical `<input>` or `writing-mode: lr` -> needs to be replaced by custom volume slider div 

#### Linux, Chromium, Firefox 

- initial sound stuttering (perhaps just bad sound card or system audio configurations)

    -> apparently gone with new audio buffering

#### Apple devices

- usually don't decode ogg files (-> m4a is the smallest solution, mp3 is also very good)



