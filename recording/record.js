const { spawn } = require('child_process');

const args = process.argv.slice(2);
const REC_URL = args[0];
console.log(`[recording process] REC_URL: ${REC_URL}`);
const BROWSER_SCREEN_WIDTH = args[1];
const BROWSER_SCREEN_HEIGHT = args[2];
console.log(`[recording process] BROWSER_SCREEN_WIDTH: ${BROWSER_SCREEN_WIDTH}, BROWSER_SCREEN_HEIGHT: ${BROWSER_SCREEN_HEIGHT}`);

const VIDEO_BITRATE = 3000;
const VIDEO_FRAMERATE = 30;
const VIDEO_GOP = VIDEO_FRAMERATE * 2;
const AUDIO_BITRATE = '160k';
const AUDIO_SAMPLERATE = 44100;
const AUDIO_CHANNELS = 2
const DISPLAY = process.env.DISPLAY;

const timestamp = new Date();
const fileTimestamp = timestamp.toISOString().substring(0,19);
const year = timestamp.getFullYear();
const month = timestamp.getMonth() + 1;
const day = timestamp.getDate();
const hour = timestamp.getUTCHours();
const fileName = `${year}-${month}-${day}-${hour}-${fileTimestamp}.mp4`;


// const vncOutput = spawn('ffmpeg',['x11vnc','-display',':1']);

let transcodeStreamToOutput = false;

// event handler for docker stop, not exit until upload completes
process.on('SIGTERM', (code, signal) => {
    console.log(`[recording process] 1 exited with code ${code} and signal ${signal}(SIGTERM)`);
    if( transcodeStreamToOutput )
        process.kill(transcodeStreamToOutput.pid, 'SIGTERM');
});

// debug use - event handler for ctrl + c
process.on('SIGINT', (code, signal) => {
    console.log(`[recording process] 2 exited with code ${code} and signal ${signal}(SIGINT)`)
    process.kill(process.pid,'SIGTERM');
    process.exit();
});

process.on('exit', function(code) {
    console.log('[recording process] exit code', code);
});

const express = require('express')
const cors = require('cors')
const app = express()
app.use(cors())

app.get('/stop', function (req, res) {
    
    setTimeout( ()=>
    {
        process.kill(process.pid,'SIGTERM');
        process.exit();
    }, 3000 );
    res.json({"code":0,"message":"done","detail":"stopping in 3 seconds"});
});

app.get('/start', function (req, res) {
    transcodeStreamToOutput = spawn('ffmpeg',[
        '-hide_banner',
        '-loglevel', 'error',
        // disable interaction via stdin
        '-nostdin',
        // screen image size
        '-s', `${BROWSER_SCREEN_WIDTH}x${BROWSER_SCREEN_HEIGHT}`,
        // video frame rate
        '-r', `${VIDEO_FRAMERATE}`,
        // hides the mouse cursor from the resulting video
        '-draw_mouse', '0',
        // grab the x11 display as video input
        '-f', 'x11grab',
            '-i', `${DISPLAY}`,
        // grab pulse as audio input
        '-f', 'pulse', 
            '-ac', '2',
            '-i', 'default',
        // codec video with libx264
        '-c:v', 'libx264',
            '-pix_fmt', 'yuv420p',
            '-profile:v', 'main',
            '-preset', 'veryfast',
            '-x264opts', 'nal-hrd=cbr:no-scenecut',
            '-minrate', `${VIDEO_BITRATE}`,
            '-maxrate', `${VIDEO_BITRATE}`,
            '-g', `${VIDEO_GOP}`,
        // apply a fixed delay to the audio stream in order to synchronize it with the video stream
        '-filter_complex', 'adelay=delays=1000|1000',
        // codec audio with aac
        '-c:a', 'aac',
            '-b:a', `${AUDIO_BITRATE}`,
            '-ac', `${AUDIO_CHANNELS}`,
            '-ar', `${AUDIO_SAMPLERATE}`,
        // adjust fragmentation to prevent seeking(resolve issue: muxer does not support non seekable output)
        '-movflags', 'frag_keyframe+empty_moov',
        // set output format to mp4 and output file to stdout
        '-f', 'mp4', '/data/'+fileName
        ]
    );
    
    transcodeStreamToOutput.stderr.on('data', data => {
        console.log(`[transcodeStreamToOutput process] stderr: ${(new Date()).toISOString()} ffmpeg: ${data}`);
    });

    console.log(`[recording process] start recording`);
    res.json({"code":0,"message":"done"});
} );

app.listen(80);