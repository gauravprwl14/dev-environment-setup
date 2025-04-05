/**
 * Media detector functionality for identifying media elements in Telegram Web
 * @module core/detector
 */

import { logger } from '../utils/logger.js';
import { getTelegramElements } from '../utils/dom.js';

/**
 * Detects if the current page has a media viewer open
 * @returns {boolean} True if a media viewer is detected
 * 
 * @example
 * if (hasMediaViewer()) {
 *   // Handle media viewer UI updates
 * }
 */
export const hasMediaViewer = () => {
    const mediaViewer = document.querySelector('#MediaViewer');
    return !!mediaViewer && window.getComputedStyle(mediaViewer).display !== 'none';
};

/**
 * Detects if the current page has a story viewer open
 * @returns {boolean} True if a story viewer is detected
 * 
 * @example
 * if (hasStoryViewer()) {
 *   // Handle story viewer UI updates
 * }
 */
export const hasStoryViewer = () => {
    const storyViewer = document.getElementById('StoryViewer') ||
        document.getElementById('stories-viewer');
    return !!storyViewer && window.getComputedStyle(storyViewer).display !== 'none';
};

/**
 * Gets the active video element from the media viewer
 * @returns {HTMLElement|null} The video element or null if not found
 * 
 * @example
 * const videoElement = getActiveVideoElement();
 * if (videoElement) {
 *   const videoUrl = videoElement.src;
 * }
 */
export const getActiveVideoElement = () => {
    const elements = getTelegramElements('mediaViewer');
    if (!elements) return null;

    // For webk (/k/) app version
    if (elements.videoPlayer) {
        const video = elements.videoPlayer.querySelector('video.media-viewer-video');
        if (video && video.src) return video;
    }

    // For webz (/a/) app version
    const video = elements.content?.querySelector('video.MediaViewerContent--video');
    if (video && video.src) return video;

    return null;
};

/**
 * Gets the active image element from the media viewer
 * @returns {HTMLElement|null} The image element or null if not found
 * 
 * @example
 * const imageElement = getActiveImageElement();
 * if (imageElement) {
 *   const imageUrl = imageElement.src;
 * }
 */
export const getActiveImageElement = () => {
    const elements = getTelegramElements('mediaViewer');
    if (!elements || !elements.content) return null;

    // Try to find the image in different DOM structures
    const image = elements.image ||
        elements.content.querySelector('img.MediaViewerContent--image') ||
        elements.content.querySelector('img');

    if (image && image.src) return image;

    return null;
};

/**
 * Gets the active audio element in the chat
 * @returns {HTMLElement|null} The audio element or null if not found
 * 
 * @example
 * const audioElement = getActiveAudioElement();
 * if (audioElement) {
 *   const audioUrl = audioElement.src;
 * }
 */
export const getActiveAudioElement = () => {
    // Find audio elements in voice messages
    const audioElements = document.querySelectorAll('audio.voice-message-audio');
    for (const audio of audioElements) {
        if (audio && audio.src) return audio;
    }

    return null;
};

/**
 * Gets the active story element (video or image)
 * @returns {Object|null} An object containing the story element and its type
 * 
 * @example
 * const storyElement = getActiveStoryElement();
 * if (storyElement) {
 *   if (storyElement.type === 'video') {
 *     // Handle video story
 *   } else {
 *     // Handle image story
 *   }
 * }
 */
export const getActiveStoryElement = () => {
    const elements = getTelegramElements('story');
    if (!elements) return null;

    // Check for video first
    if (elements.video && elements.video.src) {
        return {
            element: elements.video,
            type: 'video'
        };
    }

    // Then check for image
    if (elements.image && elements.image.src) {
        return {
            element: elements.image,
            type: 'image'
        };
    }

    return null;
};