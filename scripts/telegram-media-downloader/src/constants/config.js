/**
 * Configuration constants for the application
 */

// Regular expression to parse Content-Range header
export const CONTENT_RANGE_REGEX = /^bytes (\d+)-(\d+)\/(\d+)$/;

// Refresh delay for checking DOM elements (in milliseconds)
export const REFRESH_DELAY = 500;

// Default CSS classes and IDs for UI elements
export const UI = {
    PROGRESS_CONTAINER_ID: 'tel-downloader-progress-bar-container',
    PROGRESS_CLASS: 'tel-download',
    DOWNLOAD_BUTTON_CLASS: 'tel-download'
};