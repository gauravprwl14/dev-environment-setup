/**
 * Image downloader functionality
 * @module downloaders/image-downloader
 */

import { logger } from '../utils/logger.js';
import { generateFileName } from '../utils/file.js';
import { triggerDownload } from '../utils/dom.js';

/**
 * Downloads an image from the provided URL
 * @param {string} url - The URL of the image to download
 * @returns {void}
 * 
 * @example
 * // Download an image from a URL
 * downloadImage('https://example.com/image.jpg');
 */
export const downloadImage = (url) => {
    if (!url) {
        logger.error('Image URL is empty or invalid');
        return;
    }

    // Determine file extension from URL if possible, default to jpeg
    let fileExtension = 'jpeg';

    try {
        const urlPath = new URL(url).pathname;
        const lastSegment = urlPath.split('/').pop();

        if (lastSegment && lastSegment.includes('.')) {
            const extension = lastSegment.split('.').pop().toLowerCase();
            // Only use common image extensions
            if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].includes(extension)) {
                fileExtension = extension;
            }
        }
    } catch (error) {
        logger.error(`Error parsing URL for extension: ${error.message}`);
        // Continue with default extension
    }

    // Generate a random file name with the determined extension
    const fileName = (Math.random() + 1).toString(36).substring(2, 10) + '.' + fileExtension;

    logger.info(`Downloading image: ${url}`, fileName);

    // For images, we can use a direct download approach
    triggerDownload(url, fileName);

    logger.info('Download triggered', fileName);
};