/**
 * Audio downloader functionality
 * @module downloaders/audio-downloader
 */

import { CONTENT_RANGE_REGEX } from '../constants/config.js';
import { logger } from '../utils/logger.js';
import { supportsFileSystemAccess, generateFileName } from '../utils/file.js';
import { triggerDownload, createBlobUrl, revokeBlobUrl } from '../utils/dom.js';

/**
 * Downloads an audio file from the provided URL
 * @param {string} url - The URL of the audio to download
 * @returns {void}
 * 
 * @example
 * // Download an audio file from a URL
 * downloadAudio('https://example.com/audio.ogg');
 */
export const downloadAudio = (url) => {
    if (!url) {
        logger.error('Audio URL is empty or invalid');
        return;
    }

    let blobs = [];
    let nextOffset = 0;
    let totalSize = null;

    // Default extension for audio in Telegram is ogg
    const fileName = generateFileName(url, 'ogg');

    logger.info(`Starting audio download: ${url}`, fileName);

    /**
     * Fetches the next part of the audio
     * @param {FileSystemWritableFileStream|null} writable - Writable stream for File System Access API
     * @returns {Promise<void>}
     */
    const fetchNextPart = async (writable) => {
        try {
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    Range: `bytes=${nextOffset}-`,
                },
            });

            if (![200, 206].includes(response.status)) {
                logger.error(`Non 200/206 response was received: ${response.status}`, fileName);
                return;
            }

            const contentType = response.headers.get('Content-Type');
            const mime = contentType ? contentType.split(';')[0] : '';

            if (!mime.startsWith('audio/')) {
                logger.error(`Get non-audio response with MIME type ${mime}`, fileName);
                throw new Error(`Get non-audio response with MIME type ${mime}`);
            }

            // Process Content-Range header if available
            const contentRange = response.headers.get('Content-Range');
            if (contentRange) {
                try {
                    const match = contentRange.match(CONTENT_RANGE_REGEX);

                    if (match) {
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
                    }
                } catch (error) {
                    logger.error(`Error parsing Content-Range: ${error.message}`, fileName);
                    throw error;
                }
            }

            logger.info(`Received ${response.headers.get('Content-Length')} bytes from ${contentRange || 'unknown range'}`, fileName);

            const resBlob = await response.blob();

            if (writable !== null) {
                await writable.write(resBlob);
            } else {
                blobs.push(resBlob);
            }

            if (totalSize && nextOffset < totalSize) {
                // Continue fetching
                fetchNextPart(writable);
            } else {
                // We're done or there's no Content-Range
                if (writable !== null) {
                    await writable.close();
                    logger.info('Download finished using File System Access API', fileName);
                } else {
                    saveBlobs();
                }
            }
        } catch (error) {
            logger.error(`Error downloading audio: ${error.message}`, fileName);
        }
    };

    /**
     * Saves the accumulated blobs as a downloaded file
     */
    const saveBlobs = () => {
        logger.info('Concatenating blobs and downloading...', fileName);

        const blob = new Blob(blobs, { type: 'audio/ogg' });
        const blobUrl = createBlobUrl(blob, 'audio/ogg');

        logger.info(`Final blob size: ${blob.size} bytes`, fileName);

        triggerDownload(blobUrl, fileName);
        revokeBlobUrl(blobUrl);

        // Clear blobs to free memory
        blobs = [];

        logger.info('Download triggered', fileName);
    };

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