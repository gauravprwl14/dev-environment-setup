/**
 * Progress bar UI component for displaying download progress
 * @module ui/progress-bar
 */

import { UI } from '../constants/config.js';
import { isDarkMode } from '../utils/dom.js';
import { logger } from '../utils/logger.js';

/**
 * Ensures the progress bar container exists in the DOM
 * Creates it if it doesn't exist
 * 
 * @example
 * // Initialize the progress bar container at the start of the application
 * setupProgressBarContainer();
 */
export const setupProgressBarContainer = () => {
    if (document.getElementById(UI.PROGRESS_CONTAINER_ID)) {
        return; // Container already exists
    }

    const body = document.querySelector('body');
    const container = document.createElement('div');
    container.id = UI.PROGRESS_CONTAINER_ID;
    container.style.position = 'fixed';
    container.style.bottom = '0';
    container.style.right = '0';

    // Set z-index based on the Telegram app version
    if (location.pathname.startsWith('/k/')) {
        container.style.zIndex = '4';
    } else {
        container.style.zIndex = '1600';
    }

    body.appendChild(container);

    logger.info('Progress bar container initialized');
};

/**
 * Creates a progress bar for tracking download progress
 * @param {string} id - Unique identifier for the progress bar
 * @param {string} fileName - The name of the file being downloaded
 * @returns {void}
 * 
 * @example
 * // Create a progress bar for tracking a video download
 * createProgressBar('video_123', 'vacation.mp4');
 */
export const createProgressBar = (id, fileName) => {
    const container = document.getElementById(UI.PROGRESS_CONTAINER_ID);
    if (!container) {
        logger.error('Progress bar container not found');
        return;
    }

    const isDarkTheme = isDarkMode();

    const innerContainer = document.createElement('div');
    innerContainer.id = 'tel-downloader-progress-' + id;
    innerContainer.style.width = '20rem';
    innerContainer.style.marginTop = '0.4rem';
    innerContainer.style.padding = '0.6rem';
    innerContainer.style.backgroundColor = isDarkTheme
        ? 'rgba(0,0,0,0.3)'
        : 'rgba(0,0,0,0.6)';

    const flexContainer = document.createElement('div');
    flexContainer.style.display = 'flex';
    flexContainer.style.justifyContent = 'space-between';

    const title = document.createElement('p');
    title.className = 'filename';
    title.style.margin = 0;
    title.style.color = 'white';
    title.innerText = fileName;

    const closeButton = document.createElement('div');
    closeButton.style.cursor = 'pointer';
    closeButton.style.fontSize = '1.2rem';
    closeButton.style.color = isDarkTheme ? '#8a8a8a' : 'white';
    closeButton.innerHTML = '&times;';
    closeButton.onclick = function () {
        container.removeChild(innerContainer);
    };

    const progressBar = document.createElement('div');
    progressBar.className = 'progress';
    progressBar.style.backgroundColor = '#e2e2e2';
    progressBar.style.position = 'relative';
    progressBar.style.width = '100%';
    progressBar.style.height = '1.6rem';
    progressBar.style.borderRadius = '2rem';
    progressBar.style.overflow = 'hidden';

    const counter = document.createElement('p');
    counter.style.position = 'absolute';
    counter.style.zIndex = 5;
    counter.style.left = '50%';
    counter.style.top = '50%';
    counter.style.transform = 'translate(-50%, -50%)';
    counter.style.margin = 0;
    counter.style.color = 'black';

    const progress = document.createElement('div');
    progress.style.position = 'absolute';
    progress.style.height = '100%';
    progress.style.width = '0%';
    progress.style.backgroundColor = '#6093B5';

    progressBar.appendChild(counter);
    progressBar.appendChild(progress);
    flexContainer.appendChild(title);
    flexContainer.appendChild(closeButton);
    innerContainer.appendChild(flexContainer);
    innerContainer.appendChild(progressBar);
    container.appendChild(innerContainer);

    logger.info(`Progress bar created for ${fileName}`, id);
};

/**
 * Updates the progress displayed on an existing progress bar
 * @param {string} id - The ID of the progress bar to update
 * @param {string} fileName - The file name to display
 * @param {number|string} progress - The progress percentage (0-100)
 * @returns {void}
 * 
 * @example
 * // Update progress to 45%
 * updateProgress('video_123', 'vacation.mp4', 45);
 */
export const updateProgress = (id, fileName, progress) => {
    const innerContainer = document.getElementById('tel-downloader-progress-' + id);
    if (!innerContainer) {
        logger.error(`Progress bar with ID ${id} not found`);
        return;
    }

    innerContainer.querySelector('p.filename').innerText = fileName;
    const progressBar = innerContainer.querySelector('div.progress');
    progressBar.querySelector('p').innerText = progress + '%';
    progressBar.querySelector('div').style.width = progress + '%';

    logger.info(`Progress updated: ${progress}%`, fileName);
};

/**
 * Marks a progress bar as completed
 * @param {string} id - The ID of the progress bar to mark as complete
 * @returns {void}
 * 
 * @example
 * // Mark a download as completed
 * completeProgress('video_123');
 */
export const completeProgress = (id) => {
    const progressBar = document.getElementById('tel-downloader-progress-' + id);
    if (!progressBar) {
        logger.error(`Progress bar with ID ${id} not found`);
        return;
    }

    const bar = progressBar.querySelector('div.progress');
    bar.querySelector('p').innerText = 'Completed';
    bar.querySelector('div').style.backgroundColor = '#B6C649';
    bar.querySelector('div').style.width = '100%';

    logger.info(`Download completed for ID ${id}`);
};

/**
 * Marks a progress bar as aborted
 * @param {string} id - The ID of the progress bar to mark as aborted
 * @returns {void}
 * 
 * @example
 * // Mark a download as aborted
 * abortProgress('video_123');
 */
export const abortProgress = (id) => {
    const progressBar = document.getElementById('tel-downloader-progress-' + id);
    if (!progressBar) {
        logger.error(`Progress bar with ID ${id} not found`);
        return;
    }

    const bar = progressBar.querySelector('div.progress');
    bar.querySelector('p').innerText = 'Aborted';
    bar.querySelector('div').style.backgroundColor = '#D16666';
    bar.querySelector('div').style.width = '100%';

    logger.info(`Download aborted for ID ${id}`);
};