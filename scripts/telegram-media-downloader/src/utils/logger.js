/**
 * Logger utility for consistent logging across the application
 * @module utils/logger
 */

/**
 * Logger class for standardized logging
 */
class Logger {
    /**
     * Log an informational message
     * @param {string} message - The message to log
     * @param {string|null} [fileName=null] - Optional file name for context
     * 
     * @example
     * // Without fileName
     * logger.info('Download started');
     * // Output: [Tel Download] Download started
     * 
     * @example
     * // With fileName
     * logger.info('Download started', 'video.mp4');
     * // Output: [Tel Download] video.mp4: Download started
     */
    info(message, fileName = null) {
        console.log(`[Tel Download] ${fileName ? `${fileName}: ` : ""}${message}`);
    }

    /**
     * Log an error message
     * @param {string} message - The error message to log
     * @param {string|null} [fileName=null] - Optional file name for context
     * 
     * @example
     * // Without fileName
     * logger.error('Download failed');
     * // Output: [Tel Download] Download failed
     * 
     * @example
     * // With fileName
     * logger.error('Download failed', 'video.mp4');
     * // Output: [Tel Download] video.mp4: Download failed
     */
    error(message, fileName = null) {
        console.error(`[Tel Download] ${fileName ? `${fileName}: ` : ""}${message}`);
    }
}

// Export a singleton instance
export const logger = new Logger();