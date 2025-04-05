/**
 * Detection functionality for finding media elements in Telegram Web
 * @module core/detector
 * 
 * WHAT THIS FILE DOES:
 * -------------------
 * This file contains functions that scan the webpage to find media elements
 * that the user might want to download from Telegram Web.
 * 
 * In simple terms, it's the "eyes" of the extension - it looks for:
 * 1. Images in media viewers and stories
 * 2. Videos in media viewers and stories
 * 3. Voice messages in chats
 * 
 * The detection functions support both versions of Telegram Web:
 * - web.telegram.org/a/ (webz)
 * - web.telegram.org/k/ (webk)
 * 
 * TECHNICAL DETAILS:
 * -----------------
 * The detector uses DOM querying functions to find specific elements with 
 * particular CSS classes and attributes that identify media elements in
 * Telegram's interface. It has specialized detection for different media types
 * and different Telegram web app versions.
 */

import { logger } from '../utils/logger.js';

/**
 * Checks if a media viewer is currently open
 * @returns {boolean} True if a media viewer is detected
 * 
 * HOW IT WORKS:
 * This function checks for the presence of Telegram's media viewer component
 * in the DOM. It supports both web.telegram.org/a/ and web.telegram.org/k/
 * interfaces by looking for specific CSS selectors that identify the media viewer
 * in each version.
 * 
 * @example
 * if (hasMediaViewer()) {
 *   // Media viewer is open, we can look for downloadable content
 * }
 */
export const hasMediaViewer = () => {
    const isWebKApp = location.pathname.startsWith('/k/');

    if (isWebKApp) {
        // For webk (/k/) app version
        return !!document.querySelector('.media-viewer-whole');
    } else {
        // For webz (/a/) app version
        return !!document.querySelector('#MediaViewer');
    }
};

/**
 * Checks if a story viewer is currently open
 * @returns {boolean} True if a story viewer is detected
 * 
 * HOW IT WORKS:
 * This function checks for the presence of Telegram's story viewer component
 * in the DOM. Stories are a newer feature in Telegram, and this function
 * supports detection in both web interfaces.
 * 
 * @example
 * if (hasStoryViewer()) {
 *   // Story viewer is open, we can look for downloadable story content
 * }
 */
export const hasStoryViewer = () => {
    const isWebKApp = location.pathname.startsWith('/k/');

    if (isWebKApp) {
        // For webk (/k/) app version
        return !!document.getElementById('stories-viewer');
    } else {
        // For webz (/a/) app version
        return !!document.getElementById('StoryViewer');
    }
};

/**
 * Gets the currently active video element in the media viewer
 * @returns {HTMLElement|null} The video element or null if not found
 * 
 * HOW IT WORKS:
 * This function finds the currently displayed video in Telegram's media viewer.
 * It looks for different video player implementations in both Telegram interfaces
 * and returns the actual video element. This element contains the video source URL
 * which can be used for downloading.
 * 
 * @example
 * const videoElement = getActiveVideoElement();
 * if (videoElement) {
 *   const videoUrl = videoElement.src;
 *   // Now we can use the URL to download the video
 * }
 */
export const getActiveVideoElement = () => {
    const isWebKApp = location.pathname.startsWith('/k/');

    if (isWebKApp) {
        // For webk (/k/) app version
        const mediaContainer = document.querySelector('.media-viewer-whole');
        if (!mediaContainer) return null;

        const mediaAspecter = mediaContainer.querySelector('.media-viewer-movers .media-viewer-aspecter');
        if (!mediaAspecter) return null;

        // First check for the video player with controls
        if (mediaAspecter.querySelector('.ckin__player')) {
            return mediaAspecter.querySelector('.ckin__player video');
        }

        // Then check for simple video element (could be a GIF)
        return mediaAspecter.querySelector('video');
    } else {
        // For webz (/a/) app version
        const mediaContainer = document.querySelector('#MediaViewer .MediaViewerSlide--active');
        if (!mediaContainer) return null;

        const videoPlayer = mediaContainer.querySelector('.MediaViewerContent > .VideoPlayer');
        if (!videoPlayer) return null;

        return videoPlayer.querySelector('video');
    }
};

/**
 * Gets the currently active image element in the media viewer
 * @returns {HTMLElement|null} The image element or null if not found
 * 
 * HOW IT WORKS:
 * This function finds the currently displayed image in Telegram's media viewer.
 * It returns the image element which contains the source URL that can be used
 * for downloading the full-resolution image.
 * 
 * @example
 * const imageElement = getActiveImageElement();
 * if (imageElement) {
 *   const imageUrl = imageElement.src;
 *   // Now we can use the URL to download the image
 * }
 */
export const getActiveImageElement = () => {
    const isWebKApp = location.pathname.startsWith('/k/');

    if (isWebKApp) {
        // For webk (/k/) app version
        const mediaContainer = document.querySelector('.media-viewer-whole');
        if (!mediaContainer) return null;

        const mediaAspecter = mediaContainer.querySelector('.media-viewer-movers .media-viewer-aspecter');
        if (!mediaAspecter) return null;

        // Look for the thumbnail image
        return mediaAspecter.querySelector('img.thumbnail');
    } else {
        // For webz (/a/) app version
        const mediaContainer = document.querySelector('#MediaViewer .MediaViewerSlide--active');
        if (!mediaContainer) return null;

        // Look for the image in the content container
        return mediaContainer.querySelector('.MediaViewerContent > div > img');
    }
};

/**
 * Gets the currently active story element (video or image)
 * @returns {Object|null} Object with type and element, or null if not found
 * 
 * HOW IT WORKS:
 * This function detects media in the story viewer, which can be either videos or images.
 * It returns an object that includes the type of media ('video' or 'image')
 * and the DOM element itself, which contains the source URL.
 * 
 * @example
 * const storyElement = getActiveStoryElement();
 * if (storyElement) {
 *   if (storyElement.type === 'video') {
 *     // Handle video story
 *   } else if (storyElement.type === 'image') {
 *     // Handle image story
 *   }
 * }
 */
export const getActiveStoryElement = () => {
    const isWebKApp = location.pathname.startsWith('/k/');

    if (isWebKApp) {
        // For webk (/k/) app version
        const storiesContainer = document.getElementById('stories-viewer');
        if (!storiesContainer) return null;

        // Check for video first
        const video = storiesContainer.querySelector('video.media-video');
        if (video && video.src) {
            return { type: 'video', element: video };
        }

        // Then check for image
        const image = storiesContainer.querySelector('img.media-photo');
        if (image && image.src) {
            return { type: 'image', element: image };
        }
    } else {
        // For webz (/a/) app version
        const storiesContainer = document.getElementById('StoryViewer');
        if (!storiesContainer) return null;

        // Check for video first
        const video = storiesContainer.querySelector('video');
        const videoSrc = video?.src || video?.currentSrc || video?.querySelector('source')?.src;
        if (videoSrc) {
            return { type: 'video', element: video };
        }

        // Then check for image
        const images = storiesContainer.querySelectorAll('img.PVZ8TOWS');
        if (images.length > 0) {
            const image = images[images.length - 1];
            if (image?.src) {
                return { type: 'image', element: image };
            }
        }
    }

    return null;
};

/**
 * Gets the active audio element (voice message)
 * @returns {Object|null} Object with info about the audio element, or null if not found
 * 
 * HOW IT WORKS:
 * This function finds voice messages in the chat. Voice messages in Telegram
 * are typically audio files that users record and send in conversations.
 * 
 * The function is the most complex detector because voice messages are implemented
 * very differently in the two Telegram web interfaces, particularly in the /k/ version
 * which uses custom audio elements rather than standard HTML5 audio tags.
 * 
 * @example
 * const audioElement = getActiveAudioElement();
 * if (audioElement) {
 *   // Use the audio source URL for downloading
 * }
 */
export const getActiveAudioElement = () => {
    const isWebKApp = location.pathname.startsWith('/k/');

    if (isWebKApp) {
        // For webk (/k/) app version
        // This is more complex as /k/ uses custom audio elements

        // First check for pinned audio (currently playing)
        const pinnedAudio = document.body.querySelector('.pinned-audio');
        if (pinnedAudio) {
            const dataMid = pinnedAudio.getAttribute('data-mid');
            if (dataMid) {
                // Find the corresponding audio element
                const audioElements = document.body.querySelectorAll('audio-element');
                for (const audioElement of audioElements) {
                    if (audioElement.getAttribute('data-mid') === dataMid) {
                        const audio = audioElement.audio;
                        if (audio && audio.src) {
                            return {
                                element: audio,
                                container: pinnedAudio,
                                isAudio: audio instanceof HTMLAudioElement,
                                isPinned: true
                            };
                        }
                    }
                }
            }
        }

        // Then check for other audio elements in bubbles
        const audioElements = document.body.querySelectorAll('audio-element');
        for (const audioElement of audioElements) {
            const bubble = audioElement.closest('.bubble');
            if (!bubble) continue;

            // Skip if already has download button
            if (bubble.querySelector('._tel_download_button_container')) continue;

            const audio = audioElement.audio;
            if (audio && audio.src) {
                return {
                    element: audio,
                    container: bubble,
                    isAudio: audio instanceof HTMLAudioElement,
                    isPinned: false
                };
            }
        }
    } else {
        // For webz (/a/) app version
        // Look for voice message audio elements
        const audioElements = document.querySelectorAll('audio.voice-message-audio');

        for (const audio of audioElements) {
            if (!audio || !audio.src) continue;

            const voiceMessage = audio.closest('.Voice, .voice-message');
            if (!voiceMessage) continue;

            const controlsWrapper = voiceMessage.querySelector('.MediaPlayerFooter, .voice-message-content');
            if (!controlsWrapper) continue;

            // Skip if already has download button
            if (controlsWrapper.querySelector('.tel-download')) continue;

            return {
                element: audio,
                container: voiceMessage,
                controlsContainer: controlsWrapper,
                isAudio: true,
                isPinned: false
            };
        }
    }

    return null;
};

/**
 * Utility function to log information about detected elements
 * @param {string} type - The type of element detected
 * @param {HTMLElement} element - The element that was detected
 * @returns {void}
 * 
 * @example
 * logDetection('video', videoElement);
 */
export const logDetection = (type, element) => {
    logger.info(`Detected ${type} element: ${element.tagName}`, 'detector.js');
    if (element.src) {
        logger.info(`Source URL: ${element.src}`, 'detector.js');
    }
};