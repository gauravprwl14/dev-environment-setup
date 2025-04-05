/**
 * Button UI components for the Telegram media downloader
 * @module ui/buttons
 */

import { DOWNLOAD_ICON } from '../constants/icons.js';
import { logger } from '../utils/logger.js';
import { UI } from '../constants/config.js';

/**
 * Creates a download button for the webz (/a/) app version
 * @param {Function} onClickCallback - Function to call when the button is clicked
 * @returns {HTMLElement} The created download button
 * 
 * @example
 * // Create a button that downloads a video
 * const button = createWebZDownloadButton(() => {
 *   downloadVideo('https://example.com/video.mp4');
 * });
 * container.appendChild(button);
 */
export const createWebZDownloadButton = (onClickCallback) => {
    const downloadIcon = document.createElement('i');
    downloadIcon.className = 'icon icon-download';

    const downloadButton = document.createElement('button');
    downloadButton.className = 'Button smaller translucent-white round ' + UI.DOWNLOAD_BUTTON_CLASS;
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
 * Creates a download button for the story viewer in webz (/a/) app version
 * @param {Function} onClickCallback - Function to call when the button is clicked
 * @returns {HTMLElement} The created download button
 * 
 * @example
 * // Create a button that downloads a story video
 * const button = createWebZStoryDownloadButton(() => {
 *   downloadVideo('https://example.com/story.mp4');
 * });
 * storyHeader.appendChild(button);
 */
export const createWebZStoryDownloadButton = (onClickCallback) => {
    const downloadIcon = document.createElement('i');
    downloadIcon.className = 'icon icon-download';

    const downloadButton = document.createElement('button');
    downloadButton.className = 'Button TkphaPyQ tiny translucent-white round ' + UI.DOWNLOAD_BUTTON_CLASS;
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
 * Creates a download button for the webk (/k/) app version
 * @param {Function} onClickCallback - Function to call when the button is clicked
 * @returns {HTMLElement} The created download button
 * 
 * @example
 * // Create a button that downloads an image
 * const button = createWebKDownloadButton(() => {
 *   downloadImage('https://example.com/image.jpg');
 * });
 * mediaButtons.appendChild(button);
 */
export const createWebKDownloadButton = (onClickCallback) => {
    const downloadButton = document.createElement('button');
    downloadButton.className = 'btn-icon tgico-download ' + UI.DOWNLOAD_BUTTON_CLASS;
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
 * Creates a download button for video controls in the webk (/k/) app version
 * @param {Function} onClickCallback - Function to call when the button is clicked
 * @returns {HTMLElement} The created download button
 * 
 * @example
 * // Create a button for video controls
 * const button = createWebKVideoControlsDownloadButton(() => {
 *   downloadVideo('https://example.com/video.mp4');
 * });
 * videoControls.appendChild(button);
 */
export const createWebKVideoControlsDownloadButton = (onClickCallback) => {
    const downloadButton = document.createElement('button');
    downloadButton.className = 'btn-icon default__button tgico-download ' + UI.DOWNLOAD_BUTTON_CLASS;
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
 * Creates a download button for the story viewer in webk (/k/) app version
 * @param {Function} onClickCallback - Function to call when the button is clicked
 * @returns {HTMLElement} The created download button
 * 
 * @example
 * // Create a button that downloads a story
 * const button = createWebKStoryDownloadButton(() => {
 *   downloadStory();
 * });
 * storyHeader.appendChild(button);
 */
export const createWebKStoryDownloadButton = (onClickCallback) => {
    const downloadButton = document.createElement('button');
    downloadButton.className = 'btn-icon rp ' + UI.DOWNLOAD_BUTTON_CLASS;
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
 * Adds a download button to a container if one doesn't already exist
 * @param {HTMLElement} container - The container to add the button to
 * @param {string} buttonType - The type of button to create ('webz', 'webk', 'webzStory', 'webkStory', 'webkVideoControls')
 * @param {Function} onClickCallback - Function to call when the button is clicked
 * @param {string} [position='prepend'] - Where to add the button ('prepend', 'append', or 'after', element)
 * @param {HTMLElement} [referenceElement=null] - Element to position relative to when using 'after'
 * @returns {HTMLElement|null} The created button or null if it already exists
 * 
 * @example
 * // Add a download button to media buttons
 * addDownloadButton(
 *   mediaButtons,
 *   'webz',
 *   () => downloadMedia(videoUrl),
 *   'prepend'
 * );
 */
export const addDownloadButton = (container, buttonType, onClickCallback, position = 'prepend', referenceElement = null) => {
    if (!container) {
        logger.error('Container element not provided');
        return null;
    }

    // Check if a download button already exists
    if (container.querySelector('.' + UI.DOWNLOAD_BUTTON_CLASS)) {
        logger.info('Download button already exists in container');
        return null;
    }

    let button;
    switch (buttonType) {
        case 'webz':
            button = createWebZDownloadButton(onClickCallback);
            break;
        case 'webk':
            button = createWebKDownloadButton(onClickCallback);
            break;
        case 'webzStory':
            button = createWebZStoryDownloadButton(onClickCallback);
            break;
        case 'webkStory':
            button = createWebKStoryDownloadButton(onClickCallback);
            break;
        case 'webkVideoControls':
            button = createWebKVideoControlsDownloadButton(onClickCallback);
            break;
        default:
            logger.error(`Unknown button type: ${buttonType}`);
            return null;
    }

    // Add the button to the container
    switch (position) {
        case 'prepend':
            container.prepend(button);
            break;
        case 'append':
            container.appendChild(button);
            break;
        case 'after':
            if (referenceElement && referenceElement.parentNode) {
                referenceElement.after(button);
            } else {
                logger.error('Reference element not provided for "after" position');
                container.prepend(button);
            }
            break;
        default:
            logger.error(`Unknown position: ${position}`);
            container.prepend(button);
    }

    logger.info(`Added ${buttonType} download button to container`);
    return button;
};