// imports


import {Song, songs} from "./Song.js";
import {createTableSongSelector, highlightActiveSong} from "./songSelector.js";


import {Mixer} from "./Mixer.js";

import {transportStop} from "./transportButtons.js";
import {configureTimeLine, updateTimelineMarker} from "./timeline.js";
import {updatePositionDisplay} from "./transportDisplays.js";

import {resetBPMControls} from "./bpmControls.js";
import {timelineControls, transportControls, createTransportControls, createTimelineControls} from "./controlPanels.js";
import {Master} from "./Master.js";


// #######################################
// #######################################
// #######################################
let defaultSongId = null;
export let activeSong = null;
export let playbackRate = 1;


let magicMixerContainer;
await initialize('magic-mixer')


async function initialize(magicMixerDivId) {

    // choir-mixer div as defined in html
    magicMixerContainer = document.getElementById(magicMixerDivId);
    magicMixerContainer.className = "flex-column w-100 minh-1vw";
    magicMixerContainer.style.alignItems = "center";

    await includeSongsFromHTML(magicMixerContainer);

    magicMixerContainer.appendChild(createTableSongSelector());

    await selectDefaultSong();

    updateFastUI();
    updateSlowUI();

}

/**
 * reads children with tag SONG in container, interprets content as songId
 * and loads them from database in directory songs/
 *
 * @param magicMixerContainer
 * @returns {Promise<void>}
 */
async function includeSongsFromHTML(magicMixerContainer) {

    let songId;

    for (const child of Array.from(magicMixerContainer.children)) {
        if (child.tagName === "SONG") {
            try {
                songId = child.innerHTML.trim()
                await Song.includeFromDatabase(songId);
                if (typeof child.getAttribute("load") === "string") defaultSongId = songId;
            } catch (error) {
                if (error.message === "ConfigNotFoundError") {
                    const errorNotifier = document.createElement("div");
                    errorNotifier.className = "container error w-80 round border center cursor-crosshair";
                    errorNotifier.onclick = () => errorNotifier.style.display = "none";
                    errorNotifier.innerHTML =
                        ` Could not include song.<br>
                          Check spelling of <b>${songId}</b>.<br>
                          Does <b>songs/${songId}/config.json</b> exist? <br>
            `;
                    magicMixerContainer.appendChild(errorNotifier);
                }

            }
        }

    }
}

/**
 * first check if there is parameter www.urlToMixer.com/?song=songId in Url
 * if not, fall back to defaultSongId that can be picked in HTML through <song default>
 *
 * load song only if default exists
 * @returns {Promise<void>}
 */

async function selectDefaultSong() {

    const urlSongId = new URLSearchParams(window.location.search).get("song");
    defaultSongId = urlSongId ? urlSongId : defaultSongId;

    if (defaultSongId) await selectSong(defaultSongId);

}



export async function selectSong(songId) {
    // If selected song is identical with active Song, do nothing
    if (activeSong && songs.get(songId) === activeSong) return;

    transportControls.style.display = "none";
    timelineControls.style.display = 'none';

    // if there is no active song, this is the first time song select is called
    // create empty Mixer and empty transport. consider moving this to own method initializeChoirMixer()
    if (!activeSong) {
        configureTone();
        Master.connect(Tone.Destination);
        magicMixerContainer.prepend(createTransportControls())
        magicMixerContainer.prepend(createTimelineControls())
        magicMixerContainer.prepend(Mixer.create())
    }


    // If there's an active song currently cancel everything it first!
    if (activeSong) {
        activeSong.buffer.clearLoading();
        activeSong.disconnect(); // Ensure dispose cleans up references
        transportStop();
    }

    // Now set activeSong
    activeSong = songs.get(songId);
    const mixer = Mixer.get(activeSong);
    highlightActiveSong(activeSong); // update song selector


    if (activeSong.isLoaded === true) {
        finalizeControls()
        return;
    }

    // Safely manage the loading pipeline
    try {
        const song = activeSong;
        mixer.progress.show();

        await activeSong.buffer.load();

        setTimeout(() => {
            if (song === activeSong) {
                finalizeControls();
            }
        }, 700)


        // This ONLY runs if loadSongBuffers successfully finishes without being aborted
    } catch (error) {
        if (error.name === 'AbortError') {
            console.log("Song loading aborted by user.");
        } else {
            console.error("Failed to load song due to a critical error:", error);
        }
    }
}

function finalizeControls() {
    activeSong.connect(Master.bus);

    configureTransport();
    configureTimeLine();
    resetBPMControls();

    Mixer.get(activeSong).createTrackControls();
    transportControls.style.display = "";
    timelineControls.style.display = "";

}

function configureTone() {
    Tone.context._latencyHint = "playback";
    Tone.context._lookAhead = 0.06;
    Tone.context.updateInterval = 0.03
}

function configureTransport() {
    Tone.getTransport().bpm.value = activeSong.bpm;
    Tone.getTransport().timeSignature = activeSong.timeSignature;
    Tone.getTransport().loop = true;
    Tone.getTransport().loopStart = 0;
    Tone.getTransport().loopEnd = activeSong.duration;
}


function updateSlowUI() {
    if (activeSong && activeSong.isLoaded) {
        updateTimelineMarker();
        updatePositionDisplay();
        // updateTimeDisplay()
    }

    setTimeout(updateSlowUI, 80);
}

function updateFastUI() {
    if (activeSong && activeSong.isLoaded) {
        Mixer.updateMeters()
    }

    requestAnimationFrame(updateFastUI);
}


export function updateTempo(newPlaybackRate) {
    playbackRate = newPlaybackRate;
    Tone.getTransport().bpm.value = activeSong.bpm * newPlaybackRate;
    activeSong.tracks.forEach(track => {
        track.player.playbackRate = newPlaybackRate;
    })
    configureTimeLine()
}











