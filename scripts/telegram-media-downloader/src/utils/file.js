/**
 * File utility functions for handling file operations
 * @module utils/file
 */

/**
 * Generate a hash code from a string
 * @param {string} s - The string to hash
 * @returns {number} A numeric hash value for the string
 * 
 * @example
 * // Returns a numeric hash value
 * const hash = hashCode('https://example.com/image.jpg');
 * // Output: 1234567890 (example numeric value)
 */
export const hashCode = (s) => {
    let h = 0;
    const l = s.length;

    if (l > 0) {
        for (let i = 0; i < l; i++) {
            h = ((h << 5) - h + s.charCodeAt(i)) | 0;
        }
    }

    return h >>> 0;
};

/**
 * Checks if the File System Access API is supported in the current browser context
 * @returns {boolean} True if the File System Access API is supported
 * 
 * @example
 * if (supportsFileSystemAccess()) {
 *   // Use File System Access API
 * } else {
 *   // Use fallback method
 * }
 */
export const supportsFileSystemAccess = () => {
    return "showSaveFilePicker" in window &&
        (() => {
            try {
                return window.self === window.top;
            } catch {
                return false;
            }
        })();
};

/**
 * Generate a random ID string that can be used for unique identifiers
 * @param {string} [prefix=''] - Optional prefix for the ID
 * @returns {string} A randomly generated unique ID string
 * 
 * @example
 * // Returns a random ID like "a7b3c9_1617823456789"
 * const id = generateRandomId();
 * 
 * // Returns a random ID with prefix like "download_a7b3c9_1617823456789"
 * const downloadId = generateRandomId('download_');
 */
export const generateRandomId = (prefix = '') => {
    const randomPart = (Math.random() + 1).toString(36).substring(2, 10);
    const timestamp = Date.now().toString();
    return `${prefix}${randomPart}_${timestamp}`;
};

/**
 * Generate a file name with a random component and extension
 * @param {string} url - The URL or identifier to use for hashing
 * @param {string} extension - The file extension to use
 * @returns {string} A generated file name
 * 
 * @example
 * // Returns a randomly generated filename with the specified extension
 * const filename = generateFileName('https://example.com/video', 'mp4');
 * // Output: "a1b2c3d4.mp4"
 */
export const generateFileName = (url, extension) => {
    // Add date and timestamp in standard format
    const now = new Date();
    const dateTimestamp = now.toISOString()
        .replace(/:/g, '-')
        .replace(/\..+/, ''); // Remove milliseconds

    // For a random component, use a timestamp + random string
    const randomComponent = (Math.random() + 1).toString(36).substring(2, 10);

    if (url) {
        // Use the hash code approach for consistency based on URL
        return `${dateTimestamp}_${hashCode(url).toString(36)}.${extension}`;
    }

    // Fallback to just a random name with timestamp
    return `${dateTimestamp}_${randomComponent}.${extension}`;
};

/**
 * Extracts a file name from a complex URL or JSON string (for Telegram streams)
 * @param {string} url - The URL to parse
 * @param {string} defaultName - Default file name to use if extraction fails
 * @returns {string} The extracted file name or default name
 * 
 * @example
 * // For a standard URL
 * const name = extractFileNameFromUrl('https://example.com/video.mp4', 'default.mp4');
 * // Output: "video.mp4"
 * 
 * @example
 * // For a Telegram stream URL with JSON
 * const name = extractFileNameFromUrl('stream/{"fileName":"video123.mp4"}', 'default.mp4');
 * // Output: "video123.mp4"
 */
export const extractFileNameFromUrl = (url, defaultName) => {
    // Some video src is in format:
    // 'stream/{"dcId":5,"location":{...},"size":...,"mimeType":"video/mp4","fileName":"xxxx.MP4"}'
    try {
        // For URLs that contain JSON data (Telegram stream URLs)
        if (url.includes('stream/')) {
            const jsonPart = url.split('/').pop();
            const metadata = JSON.parse(decodeURIComponent(jsonPart));

            if (metadata.fileName) {
                return metadata.fileName;
            }
        }

        // For standard URLs, extract the filename from the path
        const urlPath = new URL(url).pathname;
        const fileName = urlPath.split('/').pop();

        if (fileName && fileName.includes('.')) {
            return fileName;
        }
    } catch (e) {
        // Invalid URL or JSON string, return default
    }

    return defaultName;
};