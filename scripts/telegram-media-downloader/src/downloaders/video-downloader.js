/**
 * Video downloader functionality
 * @module downloaders/video-downloader
 * 
 * WHAT THIS FILE DOES:
 * -------------------
 * This file handles the entire process of downloading videos from Telegram Web.
 * 
 * In simple terms, it:
 * 1. Takes a video URL from Telegram
 * 2. Downloads the video in small chunks to avoid memory issues
 * 3. Shows a progress bar while downloading
 * 4. Saves the video to your computer
 * 
 * Telegram often restricts downloading videos, especially in private channels.
 * This module bypasses those restrictions by treating the video data as a stream
 * and downloading it piece by piece.
 * 
 * TECHNICAL DETAILS:
 * -----------------
 * The module implements a chunked download strategy using Range requests.
 * It supports two download methods:
 * 1. File System Access API (modern browsers)
 * 2. In-memory blob accumulation (fallback for older browsers)
 * 
 * The implementation handles different video formats, progress tracking,
 * and error handling during the download process.
 */

import { logger } from '../utils/logger.js';
import { createProgressBar, updateProgress, completeProgress, abortProgress } from '../ui/progress-bar.js';
import { generateRandomId, generateFileName } from '../utils/file.js';

/**
 * Downloads a video from a given URL
 * @param {string} url - The URL of the video to download
 * @returns {void}
 * 
 * HOW IT WORKS:
 * 1. Takes a video URL from Telegram
 * 2. Generates a unique ID and filename for the download
 * 3. Tries to use the File System Access API if available:
 *    - Opens a file save dialog for the user to choose where to save the file
 *    - Downloads the video in chunks directly to the chosen file
 * 4. Falls back to in-memory download if File System Access API is not available:
 *    - Downloads the video in chunks, storing each chunk in memory
 *    - Once all chunks are downloaded, combines them and triggers a download
 * 5. Shows a progress bar throughout the process
 * 6. Handles errors that might occur during download
 * 
 * The function has to handle different browser capabilities, network conditions,
 * and various video formats that Telegram might use.
 * 
 * @example
 * // Download a video from a Telegram URL
 * downloadVideo('https://web.telegram.org/k/stream/...');
 */
export const downloadVideo = (url) => {
    // Variables to track download state
    let blobs = [];
    let nextOffset = 0;
    let totalSize = null;
    let fileExtension = 'mp4'; // Default extension

    logger.info('Starting video download', url);
    // if (!url) {
    //     logger.error('Video URL is empty or invalid');
    //     return;
    // }

    // Generate a unique ID for this download and a temporary filename
    const videoId = generateRandomId();
    let fileName = generateFileName(url, fileExtension);

    // Try to extract the filename from Telegram stream URLs if available
    // Some video src is in format: 'stream/{"dcId":5,"location":{...},"size":...,"mimeType":"video/mp4","fileName":"xxxx.MP4"}'
    try {
        const metadata = JSON.parse(decodeURIComponent(url.split('/')[url.split('/').length - 1]));
        if (metadata.fileName) {
            fileName = metadata.fileName;
        }
    } catch (e) {
        // Invalid JSON string, pass extracting fileName
        logger.info(`Could not extract filename from URL: ${e.message}`, fileName);
    }

    logger.info(`Starting download of video: ${url}`, fileName);

    /**
     * Fetches the next chunk of the video
     * @param {FileSystemWritableFileStream|null} writable - File stream to write to (if using File System Access API)
     * @private
     * 
     * HOW IT WORKS:
     * 1. Makes a fetch request with a Range header to get only a portion of the video
     * 2. Processes the response to extract content information (type, size)
     * 3. Adds the chunk to either the file stream or the blobs array
     * 4. Updates the progress bar with the current download progress
     * 5. Recursively calls itself to fetch the next chunk until download is complete
     * 6. Triggers the save process once all chunks are downloaded
     * 
     * Using Range requests allows downloading very large videos without memory issues,
     * as only small parts of the video are in memory at any given time.
     */
    const fetchNextPart = (writable) => {
        fetch(url, {
            method: 'GET',
            headers: {
                Range: `bytes=${nextOffset}-`,
            },
            'User-Agent': 'User-Agent Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/117.0',
        })
            .then((res) => {
                if (![200, 206].includes(res.status)) {
                    throw new Error(`Non 200/206 response was received: ${res.status}`);
                }

                // Extract content type and update file extension if needed
                const mime = res.headers.get('Content-Type').split(';')[0];
                if (!mime.startsWith('video/')) {
                    throw new Error(`Get non video response with MIME type ${mime}`);
                }

                fileExtension = mime.split('/')[1];
                // Update file extension and add timestamp to filename
                const now = new Date();
                const timestamp = now.toISOString()
                    .replace(/:/g, '-')
                    .replace(/\..+/, ''); // Remove milliseconds

                const baseName = fileName.substring(0, fileName.indexOf('.'));
                fileName = `${baseName}_${timestamp}.${fileExtension}`;

                // Parse Content-Range header
                const contentRange = res.headers.get('Content-Range');
                const match = contentRange.match(/^bytes (\d+)-(\d+)\/(\d+)$/);

                if (!match) {
                    throw new Error(`Invalid Content-Range format: ${contentRange}`);
                }

                const startOffset = parseInt(match[1]);
                const endOffset = parseInt(match[2]);
                const totalSize = parseInt(match[3]);

                // Validate the response range
                if (startOffset !== nextOffset) {
                    logger.error(`Gap detected between responses. Last offset: ${nextOffset}, New start offset: ${startOffset}`, fileName);
                    throw new Error('Gap detected between responses.');
                }

                // Update download state
                nextOffset = endOffset + 1;
                totalSize = totalSize;

                logger.info(
                    `Received chunk: ${res.headers.get('Content-Length')} bytes from ${contentRange}`,
                    fileName
                );

                // Calculate and update progress
                const progress = ((nextOffset * 100) / totalSize).toFixed(0);
                logger.info(`Download progress: ${progress}%`, fileName);
                updateProgress(videoId, fileName, progress);

                return res.blob();
            })
            .then((resBlob) => {
                if (writable !== null) {
                    // Writing directly to file (File System Access API)
                    writable.write(resBlob).then(() => {
                        logger.info(`Chunk written to file, size: ${resBlob.size} bytes`, fileName);
                    });
                } else {
                    // Storing blob in memory (fallback method)
                    blobs.push(resBlob);
                }
            })
            .then(() => {
                if (!totalSize) {
                    throw new Error('Total size is NULL');
                }

                if (nextOffset < totalSize) {
                    // Continue downloading the next chunk
                    fetchNextPart(writable);
                } else {
                    // Download complete
                    if (writable !== null) {
                        writable.close().then(() => {
                            logger.info('File System API: Download finished and file saved', fileName);
                        });
                    } else {
                        // Save the accumulated blobs
                        saveBlobs();
                    }
                    completeProgress(videoId);
                }
            })
            .catch((reason) => {
                logger.error(`Download failed: ${reason}`, fileName);
                abortProgress(videoId);
            });
    };

    /**
     * Saves all accumulated blobs as a download
     * @private
     * 
     * HOW IT WORKS:
     * 1. Combines all downloaded chunks into a single Blob
     * 2. Creates a URL for this Blob
     * 3. Creates a temporary download link and triggers a click
     * 4. Cleans up the URL and temporary elements
     * 
     * This is the fallback method used when the File System Access API
     * is not available. It has memory limitations for very large files.
     */
    const saveBlobs = () => {
        logger.info('Combining blobs and preparing download', fileName);

        // Create a single blob from all chunks
        const blob = new Blob(blobs, { type: `video/${fileExtension}` });
        const blobUrl = window.URL.createObjectURL(blob);

        logger.info(`Final blob size: ${blob.size} bytes`, fileName);

        // Create a download link and trigger it
        const a = document.createElement('a');
        document.body.appendChild(a);
        a.href = blobUrl;
        a.download = fileName;
        a.click();

        // Clean up
        document.body.removeChild(a);
        window.URL.revokeObjectURL(blobUrl);
        blobs = []; // Free memory

        logger.info('Download triggered', fileName);
    };

    /**
     * Determines if the File System Access API is available
     * @private
     * @returns {boolean} True if the API is available and usable
     * 
     * HOW IT WORKS:
     * Checks if the browser supports the File System Access API
     * and if we're in a context where it can be used (top-level frame).
     */
    const supportsFileSystemAccess =
        'showSaveFilePicker' in window &&
        (() => {
            try {
                return window.self === window.top;
            } catch {
                return false;
            }
        })();

    // Create a progress bar for this download
    createProgressBar(videoId, fileName);

    // Choose download method based on browser capabilities
    if (supportsFileSystemAccess) {
        logger.info('Using File System Access API for download', fileName);

        // Show file save dialog
        window.showSaveFilePicker({
            suggestedName: fileName,
            types: [{
                description: 'Video Files',
                accept: {
                    'video/*': [`.${fileExtension}`]
                }
            }]
        })
            .then(handle => {
                return handle.createWritable();
            })
            .then(writable => {
                // Start downloading chunks directly to the file
                fetchNextPart(writable);
            })
            .catch(err => {
                if (err.name === 'AbortError') {
                    // User canceled the save dialog
                    logger.info('User canceled save dialog', fileName);
                    abortProgress(videoId);
                } else {
                    // Other errors
                    logger.error(`File System Access API error: ${err.name} - ${err.message}`, fileName);
                    // Fallback to blob method
                    logger.info('Falling back to in-memory download method', fileName);
                    fetchNextPart(null);
                }
            });
    } else {
        logger.info('File System Access API not available, using in-memory download', fileName);
        fetchNextPart(null);
    }
};