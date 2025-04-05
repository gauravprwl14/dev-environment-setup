/**
 * DOM utility functions for manipulating the Document Object Model
 * @module utils/dom
 */

/**
 * Check if the webpage is in dark mode
 * @returns {boolean} True if the page is in dark mode
 * 
 * @example
 * if (isDarkMode()) {
 *   // Apply dark mode specific styling
 * } else {
 *   // Apply light mode specific styling
 * }
 */
export const isDarkMode = () => {
    const html = document.querySelector('html');
    return html.classList.contains('night') ||
        html.classList.contains('theme-dark');
};

/**
 * Creates a download link and triggers a click event to download a file
 * @param {string} url - The URL of the file to download
 * @param {string} fileName - The name to save the file as
 * 
 * @example
 * // Downloads "example.jpg" from the given URL
 * triggerDownload('https://example.com/image.jpg', 'example.jpg');
 */
export const triggerDownload = (url, fileName) => {
    const a = document.createElement('a');
    document.body.appendChild(a);
    a.href = url;
    a.download = fileName;
    a.click();
    document.body.removeChild(a);
};

/**
 * Creates a blob URL from a Blob object
 * @param {Blob} blob - The Blob object
 * @param {string} type - The MIME type of the blob
 * @returns {string} A URL representing the Blob object
 * 
 * @example
 * // Create a blob URL for a video
 * const blobUrl = createBlobUrl(videoBlob, 'video/mp4');
 * // Use blobUrl in a video element src
 */
export const createBlobUrl = (blob, type) => {
    const typedBlob = new Blob([blob], { type });
    return window.URL.createObjectURL(typedBlob);
};

/**
 * Revoke a previously created blob URL to free memory
 * @param {string} blobUrl - The blob URL to revoke
 * 
 * @example
 * // After finishing with a blob URL
 * revokeBlobUrl('blob:https://example.com/12345-67890');
 */
export const revokeBlobUrl = (blobUrl) => {
    window.URL.revokeObjectURL(blobUrl);
};

/**
 * Get specific elements from the Telegram Web App interface
 * @param {string} type - The type of element to find ('mediaViewer', 'story', etc.)
 * @returns {Object|null} An object containing relevant DOM elements or null if not found
 * 
 * @example
 * // Get media viewer elements
 * const mediaElements = getTelegramElements('mediaViewer');
 * if (mediaElements) {
 *   // Access mediaElements.container, mediaElements.buttons, etc.
 * }
 */
export const getTelegramElements = (type) => {
    switch (type) {
        case 'mediaViewer':
            const container = document.querySelector('#MediaViewer .MediaViewerSlide--active');
            if (!container) return null;

            return {
                container,
                content: container.querySelector('.MediaViewerContent'),
                buttons: document.querySelector('#MediaViewer .MediaViewerActions'),
                videoPlayer: container.querySelector('.VideoPlayer'),
                image: container.querySelector('.MediaViewerContent > div > img')
            };

        case 'story':
            const storyContainer = document.getElementById('StoryViewer') ||
                document.getElementById('stories-viewer');
            if (!storyContainer) return null;

            return {
                container: storyContainer,
                header: storyContainer.querySelector('.GrsJNw3y') ||
                    storyContainer.querySelector('.DropdownMenu')?.parentNode ||
                    storyContainer.querySelector("[class^='_ViewerStoryHeaderRight']"),
                footer: storyContainer.querySelector("[class^='_ViewerStoryFooterRight']"),
                video: storyContainer.querySelector('video') ||
                    storyContainer.querySelector('video.media-video'),
                image: storyContainer.querySelector('img.PVZ8TOWS') ||
                    storyContainer.querySelector('img.media-photo')
            };

        default:
            return null;
    }
};