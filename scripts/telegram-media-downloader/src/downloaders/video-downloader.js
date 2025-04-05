/**
 * Video downloader functionality
 * @module downloaders/video-downloader
 */

import { CONTENT_RANGE_REGEX } from '../constants/config.js';
import { logger } from '../utils/logger.js';
import { supportsFileSystemAccess, generateFileName, extractFileNameFromUrl } from '../utils/file.js';
import { triggerDownload, createBlobUrl, revokeBlobUrl } from '../utils/dom.js';
import { createProgressBar, updateProgress, completeProgress, abortProgress } from '../ui/progress-bar.js';

/**
 * Downloads a video from the provided URL
 * @param {string} url - The URL of the video to download
 * @returns {void}
 * 
 * @example
 * // Download a video from a URL
 * downloadVideo('https://example.com/video.mp4');
 */
export const downloadVideo = (url) => {
    if (!url) {
        logger.error('Video URL is empty or invalid');
        return;
    }

    let blobs = [];
    let nextOffset = 0;
    let totalSize = null;
    let fileExtension = 'mp4';

    // Generate a unique ID for this download
    const videoId = `${(Math.random() + 1).toString(36).substring(2, 10)}_${Date.now().toString()}`;

    // Initial file name, will be updated if we can extract a better one
    let fileName = generateFileName(url, fileExtension);

    // Try to extract a better file name from the URL
    const extractedName = extractFileNameFromUrl(url, fileName);
    if (extractedName !== fileName) {
        fileName = extractedName;
        logger.info(`Using extracted file name: ${fileName}`, videoId);
    }

    logger.info(`Starting video download: ${url}`, fileName);

    /**
     * Fetches the next part of the video
     * @param {FileSystemWritableFileStream|null} writable - Writable stream for File System Access API
     * @returns {Promise<void>}
     */
    const fetchNextPart = async (writable) => {
        try {
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    Range: `bytes=${nextOffset}-`,
                    'User-Agent': 'User-Agent Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/117.0',
                },
            });

            if (![200, 206].includes(response.status)) {
                throw new Error(`Non 200/206 response was received: ${response.status}`);
            }

            const contentType = response.headers.get('Content-Type');
            const mime = contentType ? contentType.split(';')[0] : '';

            if (!mime.startsWith('video/')) {
                throw new Error(`Get non-video response with MIME type ${mime}`);
            }

            // Update file extension based on MIME type if available
            if (mime.includes('/')) {
                const newExtension = mime.split('/')[1];
                if (newExtension && fileExtension !== newExtension) {
                    fileExtension = newExtension;
                    fileName = fileName.substring(0, fileName.indexOf('.') + 1) + fileExtension;
                    logger.info(`Updated file extension to ${fileExtension}`, fileName);
                }
            }

            const contentRange = response.headers.get('Content-Range');
            if (!contentRange) {
                throw new Error('No Content-Range header in response');
            }

            const match = contentRange.match(CONTENT_RANGE_REGEX);
            if (!match) {
                throw new Error(`Invalid Content-Range format: ${contentRange}`);
            }

            const startOffset = parseInt(match[1]);
            const endOffset = parseInt(match[2]);
            const totalSizeFromHeader = parseInt(match[3]);

            if (startOffset !== nextOffset) {
                logger.error(`Gap detected between responses. Last offset: ${nextOffset}, New start offset: ${startOffset}`, fileName);
                throw new Error('Gap detected between responses');
            }

            if (totalSize && totalSizeFromHeader !== totalSize) {
                logger.error(`Total size differs. Previous: ${totalSize}, Current: ${totalSizeFromHeader}`, fileName);
                throw new Error('Total size differs');
            }

            nextOffset = endOffset + 1;
            totalSize = totalSizeFromHeader;

            logger.info(`Received ${response.headers.get('Content-Length')} bytes from ${contentRange}`, fileName);

            const progressPercentage = ((nextOffset * 100) / totalSize).toFixed(0);
            logger.info(`Progress: ${progressPercentage}%`, fileName);
            updateProgress(videoId, fileName, progressPercentage);

            const resBlob = await response.blob();

            if (writable !== null) {
                await writable.write(resBlob);
            } else {
                blobs.push(resBlob);
            }

            if (!totalSize) {
                throw new Error('Total size is NULL');
            }

            if (nextOffset < totalSize) {
                fetchNextPart(writable);
            } else {
                if (writable !== null) {
                    await writable.close();
                    logger.info('Download finished using File System Access API', fileName);
                } else {
                    saveBlobs();
                }
                completeProgress(videoId);
            }
        } catch (error) {
            logger.error(`Error downloading video: ${error.message}`, fileName);
            abortProgress(videoId);
        }
    };

    /**
     * Saves the accumulated blobs as a downloaded file
     */
    const saveBlobs = () => {
        logger.info('Concatenating blobs and downloading...', fileName);

        const blob = new Blob(blobs, { type: `video/${fileExtension}` });
        const blobUrl = createBlobUrl(blob, `video/${fileExtension}`);

        logger.info(`Final blob size: ${blob.size} bytes`, fileName);

        triggerDownload(blobUrl, fileName);
        revokeBlobUrl(blobUrl);

        // Clear the blobs array to free memory
        blobs = [];

        logger.info('Download triggered', fileName);
    };

    // Create progress bar first
    createProgressBar(videoId, fileName);

    // Check if File System Access API is supported
    if (supportsFileSystemAccess()) {
        window.showSaveFilePicker({
            suggestedName: fileName,
        })
            .then(handle => {
                handle.createWritable()
                    .then(writable => {
                        fetchNextPart(writable);
                    })
                    .catch(err => {
                        logger.error(`Error creating writable: ${err.message}`, fileName);
                        // Fall back to blob method
                        fetchNextPart(null);
                    });
            })
            .catch(err => {
                if (err.name !== 'AbortError') {
                    logger.error(`Error with file picker: ${err.message}`, fileName);
                }
                // User might have cancelled, fall back to blob method
                fetchNextPart(null);
            });
    } else {
        // If File System Access API is not supported, use the blob method
        fetchNextPart(null);
    }
};