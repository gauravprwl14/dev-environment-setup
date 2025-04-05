/**
 * Image downloader functionality
 * @module downloaders/image-downloader
 */

import { logger } from '../utils/logger.js';
import { generateFileName, extractFileNameFromUrl } from '../utils/file.js';
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

    // Default extension for images in Telegram is jpeg
    let fileName = generateFileName(url, 'jpeg');

    // Try to extract a better file name from the URL
    const extractedName = extractFileNameFromUrl(url, fileName);
    if (extractedName !== fileName) {
        fileName = extractedName;
        logger.info(`Using extracted file name: ${fileName}`);
    }

    logger.info(`Starting image download: ${url}`, fileName);

    // For images, we can simply trigger a download directly
    triggerDownload(url, fileName);

    logger.info('Download triggered', fileName);
};