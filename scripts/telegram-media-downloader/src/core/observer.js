/**
 * Observer functionality for monitoring and reacting to DOM changes
 * @module core/observer
 */

import { REFRESH_DELAY } from '../constants/config.js';
import { logger } from '../utils/logger.js';
import { getTelegramElements } from '../utils/dom.js';
import { addDownloadButton } from '../ui/buttons.js';
import { downloadVideo } from '../downloaders/video-downloader.js';
import { downloadAudio } from '../downloaders/audio-downloader.js';
import { downloadImage } from '../downloaders/image-downloader.js';
import {
    hasMediaViewer,
    hasStoryViewer,
    getActiveVideoElement,
    getActiveImageElement,
    getActiveAudioElement,
    getActiveStoryElement
} from './detector.js';

// Interval IDs for each observer
let mediaViewerObserverId = null;
let storyViewerObserverId = null;
let audioObserverId = null;

/**
 * Starts the media observer for the mediaViewer
 * @returns {void}
 * 
 * @example
 * // Start observing media viewer to add download buttons
 * startMediaViewerObserver();
 */
export const startMediaViewerObserver = () => {
    // Only start if not already active
    if (mediaViewerObserverId !== null) {
        return;
    }

    logger.info('Starting media viewer observer');

    mediaViewerObserverId = setInterval(() => {
        if (!hasMediaViewer()) {
            return;
        }

        // Check for and add download buttons for video
        const videoElement = getActiveVideoElement();
        if (videoElement && videoElement.src) {
            const mediaElements = getTelegramElements('mediaViewer');
            if (!mediaElements || !mediaElements.buttons) return;

            const isWebKApp = location.pathname.startsWith('/k/');

            addDownloadButton(
                mediaElements.buttons,
                isWebKApp ? 'webk' : 'webz',
                () => downloadVideo(videoElement.src)
            );

            // For /k/ app, also add button to video controls
            if (isWebKApp && mediaElements.videoPlayer) {
                const videoControls = mediaElements.videoPlayer.querySelector('.VideoPlayer .video-buttons');
                if (videoControls) {
                    addDownloadButton(
                        videoControls,
                        'webkVideoControls',
                        () => downloadVideo(videoElement.src)
                    );
                }
            }
        }

        // Check for and add download buttons for image
        const imageElement = getActiveImageElement();
        if (imageElement && imageElement.src) {
            const mediaElements = getTelegramElements('mediaViewer');
            if (!mediaElements || !mediaElements.buttons) return;

            const isWebKApp = location.pathname.startsWith('/k/');

            addDownloadButton(
                mediaElements.buttons,
                isWebKApp ? 'webk' : 'webz',
                () => downloadImage(imageElement.src)
            );
        }
    }, REFRESH_DELAY);
};

/**
 * Starts the story observer for story viewer
 * @returns {void}
 * 
 * @example
 * // Start observing story viewer to add download buttons
 * startStoryViewerObserver();
 */
export const startStoryViewerObserver = () => {
    // Only start if not already active
    if (storyViewerObserverId !== null) {
        return;
    }

    logger.info('Starting story viewer observer');

    storyViewerObserverId = setInterval(() => {
        if (!hasStoryViewer()) {
            return;
        }

        const storyElements = getTelegramElements('story');
        if (!storyElements || !storyElements.header) return;

        const storyMedia = getActiveStoryElement();
        if (!storyMedia || !storyMedia.element || !storyMedia.element.src) return;

        const isWebKApp = location.pathname.startsWith('/k/');

        addDownloadButton(
            storyElements.header,
            isWebKApp ? 'webkStory' : 'webzStory',
            () => {
                if (storyMedia.type === 'video') {
                    downloadVideo(storyMedia.element.src);
                } else {
                    downloadImage(storyMedia.element.src);
                }
            }
        );
    }, REFRESH_DELAY);
};

/**
 * Starts the audio observer for voice messages
 * @returns {void}
 * 
 * @example
 * // Start observing for audio elements to add download buttons
 * startAudioObserver();
 */
export const startAudioObserver = () => {
    // Only start if not already active
    if (audioObserverId !== null) {
        return;
    }

    logger.info('Starting audio observer');

    audioObserverId = setInterval(() => {
        const audioElements = document.querySelectorAll('audio.voice-message-audio');

        audioElements.forEach(audio => {
            if (!audio || !audio.src) return;

            const voiceMessage = audio.closest('.Voice, .voice-message');
            if (!voiceMessage) return;

            const controlsWrapper = voiceMessage.querySelector('.MediaPlayerFooter, .voice-message-content');
            if (!controlsWrapper) return;

            // Check if we already added a button
            if (controlsWrapper.querySelector('.tel-download')) return;

            const isWebKApp = location.pathname.startsWith('/k/');

            addDownloadButton(
                controlsWrapper,
                isWebKApp ? 'webk' : 'webz',
                () => downloadAudio(audio.src),
                'append'
            );
        });
    }, REFRESH_DELAY);
};

/**
 * Stops all active observers
 * @returns {void}
 * 
 * @example
 * // Stop all observers when cleaning up
 * stopAllObservers();
 */
export const stopAllObservers = () => {
    if (mediaViewerObserverId !== null) {
        clearInterval(mediaViewerObserverId);
        mediaViewerObserverId = null;
        logger.info('Stopped media viewer observer');
    }

    if (storyViewerObserverId !== null) {
        clearInterval(storyViewerObserverId);
        storyViewerObserverId = null;
        logger.info('Stopped story viewer observer');
    }

    if (audioObserverId !== null) {
        clearInterval(audioObserverId);
        audioObserverId = null;
        logger.info('Stopped audio observer');
    }
};

/**
 * Starts all observers
 * @returns {void}
 * 
 * @example
 * // Initialize all observers at once
 * startAllObservers();
 */
export const startAllObservers = () => {
    startMediaViewerObserver();
    startStoryViewerObserver();
    startAudioObserver();
    logger.info('All observers started');
};