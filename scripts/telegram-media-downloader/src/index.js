/**
 * Telegram Media Downloader
 * @name Telegram Media Downloader
 * @description Download media from Telegram Web App
 * @version 1.0.0
 * @author Gaurav Porwal (refactored)
 * @match https://web.telegram.org/*
 * @grant none
 */

import { setupProgressBarContainer } from './ui/progress-bar.js';
import { startAllObservers } from './core/observer.js';
import { logger } from './utils/logger.js';

/**
 * Main initialization function
 * Sets up the environment and starts all observers
 */
const init = () => {
    logger.info('Telegram Media Downloader initialized');

    // Set up the progress bar container
    setupProgressBarContainer();

    // Start all observers
    startAllObservers();

    logger.info('Ready to download media');
};

// Self-executing function to start the script
(function () {
    'use strict';

    // Wait for the page to be fully loaded
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();