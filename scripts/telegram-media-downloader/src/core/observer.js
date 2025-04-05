/**
 * Observer functionality for monitoring and reacting to DOM changes
 * @module core/observer
 * 
 * WHAT THIS FILE DOES:
 * -------------------
 * This file is the "watcher" for the extension. It continuously monitors the Telegram web
 * interface for media that can be downloaded and adds custom download buttons when media is found.
 * 
 * Think of it as a security guard that patrols the page every few milliseconds, checking
 * if there's any media visible, and then adding download buttons when needed.
 * 
 * The file handles three main observers:
 * 1. Media Viewer Observer - For photos and videos opened in the full-screen viewer
 * 2. Story Viewer Observer - For Telegram stories (videos and images)
 * 3. Audio Observer - For voice messages in chat conversations
 * 
 * TECHNICAL DETAILS:
 * -----------------
 * The observers use setInterval to periodically check the DOM for media elements.
 * When media is detected, the appropriate button is created and added to the Telegram interface.
 * The observers handle both web.telegram.org/a/ (webz) and web.telegram.org/k/ (webk) interfaces.
 * Each type of observer can be started and stopped independently.
 */

import { REFRESH_DELAY } from '../constants/config.js';
import { DOWNLOAD_ICON } from '../constants/icons.js';
import { logger } from '../utils/logger.js';
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
 * Creates a download button for webz (/a/) app version
 * @private
 * @param {Function} onClickCallback - Function to call on click
 * @returns {HTMLElement} The created button
 * 
 * HOW IT WORKS:
 * This creates a button that matches Telegram's design style for the /a/ version.
 * The button has a download icon and is styled to blend in with Telegram's UI.
 */
const createWebZDownloadButton = (onClickCallback) => {
    const downloadIcon = document.createElement('i');
    downloadIcon.className = 'icon icon-download';

    const downloadButton = document.createElement('button');
    downloadButton.className = 'Button smaller translucent-white round tel-download';
    downloadButton.setAttribute('type', 'button');
    downloadButton.setAttribute('title', 'Download');
    downloadButton.setAttribute('aria-label', 'Download');
    downloadButton.appendChild(downloadIcon);

    if (onClickCallback && typeof onClickCallback === 'function') {
        downloadButton.onclick = onClickCallback;
    }

    return downloadButton;
};

/**
 * Creates a download button for webz (/a/) story viewer
 * @private
 * @param {Function} onClickCallback - Function to call on click
 * @returns {HTMLElement} The created button
 * 
 * HOW IT WORKS:
 * This creates a button specifically for the story viewer in the /a/ version.
 * Stories have a different UI styling than the regular media viewer.
 */
const createWebZStoryDownloadButton = (onClickCallback) => {
    const downloadIcon = document.createElement('i');
    downloadIcon.className = 'icon icon-download';

    const downloadButton = document.createElement('button');
    downloadButton.className = 'Button TkphaPyQ tiny translucent-white round tel-download';
    downloadButton.appendChild(downloadIcon);
    downloadButton.setAttribute('type', 'button');
    downloadButton.setAttribute('title', 'Download');
    downloadButton.setAttribute('aria-label', 'Download');

    if (onClickCallback && typeof onClickCallback === 'function') {
        downloadButton.onclick = onClickCallback;
    }

    return downloadButton;
};

/**
 * Creates a download button for webk (/k/) app version
 * @private
 * @param {Function} onClickCallback - Function to call on click
 * @returns {HTMLElement} The created button
 * 
 * HOW IT WORKS:
 * This creates a button that matches Telegram's design style for the /k/ version,
 * which has a completely different UI compared to the /a/ version.
 */
const createWebKDownloadButton = (onClickCallback) => {
    const downloadButton = document.createElement('button');
    downloadButton.className = 'btn-icon tgico-download tel-download';
    downloadButton.innerHTML = `<span class="tgico button-icon">${DOWNLOAD_ICON}</span>`;
    downloadButton.setAttribute('type', 'button');
    downloadButton.setAttribute('title', 'Download');
    downloadButton.setAttribute('aria-label', 'Download');

    if (onClickCallback && typeof onClickCallback === 'function') {
        downloadButton.onclick = onClickCallback;
    }

    return downloadButton;
};

/**
 * Creates a download button for video controls in webk (/k/) app version
 * @private
 * @param {Function} onClickCallback - Function to call on click
 * @returns {HTMLElement} The created button
 * 
 * HOW IT WORKS:
 * This creates a button specifically for video controls in the /k/ version.
 * These buttons appear in the video player's control bar rather than in the top menu.
 */
const createWebKVideoControlsDownloadButton = (onClickCallback) => {
    const downloadButton = document.createElement('button');
    downloadButton.className = 'btn-icon default__button tgico-download tel-download';
    downloadButton.innerHTML = `<span class="tgico">${DOWNLOAD_ICON}</span>`;
    downloadButton.setAttribute('type', 'button');
    downloadButton.setAttribute('title', 'Download');
    downloadButton.setAttribute('aria-label', 'Download');

    if (onClickCallback && typeof onClickCallback === 'function') {
        downloadButton.onclick = onClickCallback;
    }

    return downloadButton;
};

/**
 * Creates a download button for story viewer in webk (/k/) app version
 * @private
 * @param {Function} onClickCallback - Function to call on click
 * @returns {HTMLElement} The created button
 * 
 * HOW IT WORKS:
 * This creates a button specifically for the story viewer in the /k/ version.
 * The button includes a ripple effect to match Telegram's story viewer design.
 */
const createWebKStoryDownloadButton = (onClickCallback) => {
    const downloadButton = document.createElement('button');
    downloadButton.className = 'btn-icon rp tel-download';
    downloadButton.innerHTML = `<span class="tgico">${DOWNLOAD_ICON}</span><div class="c-ripple"></div>`;
    downloadButton.setAttribute('type', 'button');
    downloadButton.setAttribute('title', 'Download');
    downloadButton.setAttribute('aria-label', 'Download');

    if (onClickCallback && typeof onClickCallback === 'function') {
        downloadButton.onclick = onClickCallback;
    }

    return downloadButton;
};

/**
 * Starts the media observer for the mediaViewer
 * @returns {void}
 * 
 * HOW IT WORKS:
 * 1. Starts a timer that checks for media viewer elements every REFRESH_DELAY milliseconds
 * 2. When a media viewer is detected, it:
 *    - Determines which version of Telegram is being used (/a/ or /k/)
 *    - Finds the appropriate container elements
 *    - Looks for videos or images in the viewer
 *    - Creates and adds download buttons to the UI
 *    - Sets up click handlers to download the media when clicked
 * 
 * For the /k/ version, it also checks for and unhides official download buttons
 * that might be present but hidden in the interface.
 * 
 * The observer handles both adding new buttons when needed and updating existing
 * buttons when media changes, without creating duplicates.
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

        const isWebKApp = location.pathname.startsWith('/k/');

        if (isWebKApp) {
            // For webk (/k/) app version
            const mediaContainer = document.querySelector('.media-viewer-whole');
            if (!mediaContainer) return;

            const mediaAspecter = mediaContainer.querySelector('.media-viewer-movers .media-viewer-aspecter');
            const mediaButtons = mediaContainer.querySelector('.media-viewer-topbar .media-viewer-buttons');
            if (!mediaAspecter || !mediaButtons) return;

            // Check for and process hidden buttons (official download buttons)
            const hiddenButtons = mediaButtons.querySelectorAll('button.btn-icon.hide');
            let onDownload = null;

            for (const btn of hiddenButtons) {
                btn.classList.remove('hide');
                if (btn.textContent === DOWNLOAD_ICON) {
                    btn.classList.add('tgico-download');
                    onDownload = () => {
                        btn.click();
                    };
                    logger.info('Found official download button');
                }
            }

            // Check for video player
            if (mediaAspecter.querySelector('.ckin__player')) {
                // Video player detected and it has finished initial loading
                const controls = mediaAspecter.querySelector('.default__controls.ckin__controls');
                if (controls && !controls.querySelector('.tel-download')) {
                    const brControls = controls.querySelector('.bottom-controls .right-controls');
                    const downloadButton = createWebKVideoControlsDownloadButton(
                        onDownload || (() => downloadVideo(mediaAspecter.querySelector('video').src))
                    );
                    brControls.prepend(downloadButton);
                    logger.info('Added video controls download button (/k/)');
                }
            } else if (mediaAspecter.querySelector('video') && !mediaButtons.querySelector('button.btn-icon.tgico-download')) {
                // Video HTML element detected (GIF or unloaded video)
                const downloadButton = createWebKDownloadButton(
                    onDownload || (() => downloadVideo(mediaAspecter.querySelector('video').src))
                );
                mediaButtons.prepend(downloadButton);
                logger.info('Added video download button (/k/)');
            } else if (!mediaButtons.querySelector('button.btn-icon.tgico-download')) {
                // Image without download button detected
                const img = mediaAspecter.querySelector('img.thumbnail');
                if (img && img.src) {
                    const downloadButton = createWebKDownloadButton(
                        onDownload || (() => downloadImage(img.src))
                    );
                    mediaButtons.prepend(downloadButton);
                    logger.info('Added image download button (/k/)');
                }
            }
        } else {
            // For webz (/a/) app version
            const mediaContainer = document.querySelector('#MediaViewer .MediaViewerSlide--active');
            const mediaViewerActions = document.querySelector('#MediaViewer .MediaViewerActions');
            if (!mediaContainer || !mediaViewerActions) return;

            // Check for video player
            const videoPlayer = mediaContainer.querySelector('.MediaViewerContent > .VideoPlayer');
            if (videoPlayer) {
                const videoElement = videoPlayer.querySelector('video');
                if (!videoElement || !videoElement.currentSrc) return;

                const videoUrl = videoElement.currentSrc;
                const downloadButton = createWebZDownloadButton(() => downloadVideo(videoUrl));
                downloadButton.setAttribute('data-tel-download-url', videoUrl);

                // Add download button to video controls
                const controls = videoPlayer.querySelector('.VideoPlayerControls');
                if (controls) {
                    const buttons = controls.querySelector('.buttons');
                    if (buttons && !buttons.querySelector('button.tel-download')) {
                        const spacer = buttons.querySelector('.spacer');
                        if (spacer) {
                            spacer.after(downloadButton.cloneNode(true));
                            logger.info('Added video controls download button (/a/)');
                        }
                    }
                }

                // Add/Update/Remove download button to topbar
                if (mediaViewerActions.querySelector('button.tel-download')) {
                    const telDownloadButton = mediaViewerActions.querySelector('button.tel-download');
                    if (mediaViewerActions.querySelectorAll('button[title="Download"]').length > 1) {
                        // There's an existing download button, remove ours
                        mediaViewerActions.querySelector('button.tel-download').remove();
                    } else if (telDownloadButton.getAttribute('data-tel-download-url') !== videoUrl) {
                        // Update existing button
                        telDownloadButton.onclick = () => downloadVideo(videoUrl);
                        telDownloadButton.setAttribute('data-tel-download-url', videoUrl);
                    }
                } else if (!mediaViewerActions.querySelector('button[title="Download"]')) {
                    // Add the button if there's no download button at all
                    mediaViewerActions.prepend(downloadButton);
                    logger.info('Added video download button (/a/)');
                }
            } else {
                // Check for image
                const img = mediaContainer.querySelector('.MediaViewerContent > div > img');
                if (img && img.src) {
                    const downloadButton = createWebZDownloadButton(() => downloadImage(img.src));
                    downloadButton.setAttribute('data-tel-download-url', img.src);

                    // Add/Update/Remove download button to topbar
                    if (mediaViewerActions.querySelector('button.tel-download')) {
                        const telDownloadButton = mediaViewerActions.querySelector('button.tel-download');
                        if (mediaViewerActions.querySelectorAll('button[title="Download"]').length > 1) {
                            // There's an existing download button, remove ours
                            mediaViewerActions.querySelector('button.tel-download').remove();
                        } else if (telDownloadButton.getAttribute('data-tel-download-url') !== img.src) {
                            // Update existing button
                            telDownloadButton.onclick = () => downloadImage(img.src);
                            telDownloadButton.setAttribute('data-tel-download-url', img.src);
                        }
                    } else if (!mediaViewerActions.querySelector('button[title="Download"]')) {
                        // Add the button if there's no download button at all
                        mediaViewerActions.prepend(downloadButton);
                        logger.info('Added image download button (/a/)');
                    }
                }
            }
        }
    }, REFRESH_DELAY);
};

/**
 * Starts the story observer for story viewer
 * @returns {void}
 * 
 * HOW IT WORKS:
 * 1. Starts a timer that checks for story viewer elements every REFRESH_DELAY milliseconds
 * 2. When a story viewer is detected, it:
 *    - Determines which version of Telegram is being used (/a/ or /k/)
 *    - Finds the story container and header/footer elements
 *    - Creates download buttons and adds them to the appropriate containers
 *    - Sets up click handlers that detect the type of story (video/image) and download accordingly
 * 
 * Stories have a unique UI in Telegram that's different from the regular media viewer,
 * so this observer handles those specific elements and designs.
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

        const isWebKApp = location.pathname.startsWith('/k/');

        if (isWebKApp) {
            // For webk (/k/) app version
            const storiesContainer = document.getElementById('stories-viewer');
            if (!storiesContainer) return;

            const storyHeader = storiesContainer.querySelector("[class^='_ViewerStoryHeaderRight']");
            const storyFooter = storiesContainer.querySelector("[class^='_ViewerStoryFooterRight']");

            // Create download button for stories
            const createDownloadButton = () => {
                const downloadButton = createWebKStoryDownloadButton(() => {
                    // Check for video first
                    const video = storiesContainer.querySelector('video.media-video');
                    if (video && video.src) {
                        downloadVideo(video.src);
                        return;
                    }

                    // Then check for image
                    const image = storiesContainer.querySelector('img.media-photo');
                    if (image && image.src) {
                        downloadImage(image.src);
                    }
                });
                return downloadButton;
            };

            // Add button to header if not already present
            if (storyHeader && !storyHeader.querySelector('.tel-download')) {
                storyHeader.prepend(createDownloadButton());
                logger.info('Added story header download button (/k/)');
            }

            // Add button to footer if not already present
            if (storyFooter && !storyFooter.querySelector('.tel-download')) {
                storyFooter.prepend(createDownloadButton());
                logger.info('Added story footer download button (/k/)');
            }
        } else {
            // For webz (/a/) app version
            const storiesContainer = document.getElementById('StoryViewer');
            if (!storiesContainer) return;

            // Create download button for stories
            const createDownloadButton = () => {
                return createWebZStoryDownloadButton(() => {
                    // Check for video first
                    const video = storiesContainer.querySelector('video');
                    const videoSrc = video?.src || video?.currentSrc || video?.querySelector('source')?.src;
                    if (videoSrc) {
                        downloadVideo(videoSrc);
                        return;
                    }

                    // Then check for image
                    const images = storiesContainer.querySelectorAll('img.PVZ8TOWS');
                    if (images.length > 0) {
                        const imageSrc = images[images.length - 1]?.src;
                        if (imageSrc) {
                            downloadImage(imageSrc);
                        }
                    }
                });
            };

            const storyHeader = storiesContainer.querySelector('.GrsJNw3y') ||
                storiesContainer.querySelector('.DropdownMenu')?.parentNode;

            if (storyHeader && !storyHeader.querySelector('.tel-download')) {
                console.log('storyHeader found - adding button');
                storyHeader.insertBefore(createDownloadButton(), storyHeader.querySelector('button'));
                logger.info('Added story download button (/a/)');
            }
        }
    }, REFRESH_DELAY);
};

/**
 * Starts the audio observer for voice messages
 * @returns {void}
 * 
 * HOW IT WORKS:
 * 1. Starts a timer that checks for audio elements every REFRESH_DELAY milliseconds
 * 2. When voice messages are detected, it:
 *    - Determines which version of Telegram is being used (/a/ or /k/)
 *    - For /k/ version:
 *      - Handles both pinned audio (playing at the bottom of the screen) and 
 *        regular voice messages in chat bubbles
 *    - For /a/ version:
 *      - Finds voice message elements in the chat and adds download buttons to them
 * 
 * Voice messages have a complex structure in Telegram, especially in the /k/ version
 * which uses custom audio elements rather than standard HTML5 audio tags.
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
        const isWebKApp = location.pathname.startsWith('/k/');

        if (isWebKApp) {
            // For webk (/k/) app version
            const pinnedAudio = document.body.querySelector('.pinned-audio');
            let dataMid;

            if (pinnedAudio) {
                dataMid = pinnedAudio.getAttribute('data-mid');

                let downloadButtonContainer = document.body.querySelector('._tel_download_button_pinned_container');
                if (!downloadButtonContainer) {
                    downloadButtonContainer = document.createElement('button');
                    downloadButtonContainer.className = 'btn-icon tgico-download _tel_download_button_pinned_container';
                    downloadButtonContainer.innerHTML = `<span class="tgico button-icon">${DOWNLOAD_ICON}</span>`;
                }

                const audioElements = document.body.querySelectorAll('audio-element');
                for (const audioElement of audioElements) {
                    const bubble = audioElement.closest('.bubble');
                    if (!bubble || bubble.querySelector('._tel_download_button_pinned_container')) {
                        continue;
                    }

                    if (dataMid && downloadButtonContainer.getAttribute('data-mid') !== dataMid &&
                        audioElement.getAttribute('data-mid') === dataMid) {

                        const link = audioElement.audio && audioElement.audio.getAttribute('src');
                        const isAudio = audioElement.audio && audioElement.audio instanceof HTMLAudioElement;

                        if (link) {
                            downloadButtonContainer.onclick = (e) => {
                                e.stopPropagation();
                                if (isAudio) {
                                    downloadAudio(link);
                                } else {
                                    downloadVideo(link);
                                }
                            };

                            downloadButtonContainer.setAttribute('data-mid', dataMid);
                            pinnedAudio.querySelector('.pinned-container-wrapper-utils').appendChild(downloadButtonContainer);
                            logger.info('Added pinned audio download button (/k/)');
                        }
                    }
                }
            }
        } else {
            // For webz (/a/) app version
            const audioElements = document.querySelectorAll('audio.voice-message-audio');

            audioElements.forEach(audio => {
                if (!audio || !audio.src) return;

                const voiceMessage = audio.closest('.Voice, .voice-message');
                if (!voiceMessage) return;

                const controlsWrapper = voiceMessage.querySelector('.MediaPlayerFooter, .voice-message-content');
                if (!controlsWrapper) return;

                // Check if we already added a button
                if (controlsWrapper.querySelector('.tel-download')) return;

                const downloadButton = createWebZDownloadButton(() => downloadAudio(audio.src));
                controlsWrapper.appendChild(downloadButton);
                logger.info('Added audio download button (/a/)');
            });
        }
    }, REFRESH_DELAY);
};

/**
 * Stops all active observers
 * @returns {void}
 * 
 * HOW IT WORKS:
 * This function cleans up all active observers by:
 * 1. Clearing their interval timers
 * 2. Resetting their IDs to null to indicate they're stopped
 * 3. Logging the status change
 * 
 * This is useful for cleanup when the extension is disabled or when
 * you want to manually stop the observers.
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
 * HOW IT WORKS:
 * This convenience function starts all three observers at once:
 * 1. Media Viewer Observer
 * 2. Story Viewer Observer
 * 3. Audio Observer
 * 
 * It's typically called when the extension is first loaded to initialize
 * all monitoring functionality.
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