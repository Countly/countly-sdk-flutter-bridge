/* eslint-disable no-restricted-globals */
/**
 * Countly web push service worker for a Flutter web application.
 *
 * Copy this file into the "web" folder of your own application. It is served from the site root,
 * which is what lets the SDK register it. The handlers only act on Countly's own pushes and
 * notifications, so a "push" without Countly's payload is left alone.
 *
 * The imported version is pinned so that a worker already installed on a user's device does not
 * change behaviour without a deploy on your side. Keep it on the Web SDK version this plugin
 * release ships with.
 */
importScripts('https://cdn.jsdelivr.net/npm/countly-sdk-web@26.8.0/lib/countly_sw.js');
