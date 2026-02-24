/**
 * Papyrus Landing Page — Interactions
 *
 * - Navbar scroll behavior
 * - Mobile menu toggle
 * - Smooth scrolling for anchor links
 * - Theme switching with localStorage persistence
 * - Platform detection & auto-expand
 * - Platform accordion with direct downloads, QR codes & store badges
 */

(function () {
  'use strict';

  // ── Theme Config ─────────────────────────────────────────
  var THEMES = {
    'light-gold':   { metaColor: '#FDFAF5', qrDot: '#2D2A26' },
    'dark-gold':    { metaColor: '#1A1814', qrDot: '#F0EBE3' },
    'light-purple': { metaColor: '#FAFAFE', qrDot: '#1C1B1F' },
    'dark-purple':  { metaColor: '#151318', qrDot: '#E8E0F0' },
  };

  var DEFAULT_THEME = 'light-gold';

  function getCurrentTheme() {
    return document.documentElement.getAttribute('data-theme') || DEFAULT_THEME;
  }

  function setTheme(theme) {
    if (!THEMES[theme]) return;

    // Transition class for smooth color change
    document.documentElement.setAttribute('data-theme-transitioning', '');
    document.documentElement.setAttribute('data-theme', theme);

    // Update meta theme-color
    var meta = document.getElementById('meta-theme-color');
    if (meta) meta.setAttribute('content', THEMES[theme].metaColor);

    // Persist
    try { localStorage.setItem('papyrus-theme', theme); } catch (e) {}

    // Update dropdown active states
    var options = document.querySelectorAll('.theme-option');
    options.forEach(function (opt) {
      opt.classList.toggle('is-active', opt.getAttribute('data-theme') === theme);
    });

    // Remove transition class after animation
    setTimeout(function () {
      document.documentElement.removeAttribute('data-theme-transitioning');
    }, 350);

    // Regenerate QR if platform panel is open
    if (currentPlatform && PLATFORMS[currentPlatform] && PLATFORMS[currentPlatform].showQr) {
      var container = document.querySelector('.platform-qr-code[data-qr-target="' + currentPlatform + '"]');
      if (container) {
        while (container.firstChild) container.removeChild(container.firstChild);
        generateQrCode(currentPlatform);
      }
    }
  }

  // ── Navbar Scroll ──────────────────────────────────────────
  var nav = document.getElementById('nav');

  function onScroll() {
    nav.classList.toggle('scrolled', window.scrollY > 20);
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // ── Mobile Menu ────────────────────────────────────────────
  var navToggle = document.getElementById('nav-toggle');
  var navLinks = document.getElementById('nav-links');

  navToggle.addEventListener('click', function () {
    var isOpen = navLinks.classList.toggle('open');
    navToggle.classList.toggle('active', isOpen);
    navToggle.setAttribute('aria-expanded', isOpen);
  });

  navLinks.querySelectorAll('.nav-link').forEach(function (link) {
    link.addEventListener('click', function () {
      navLinks.classList.remove('open');
      navToggle.classList.remove('active');
      navToggle.setAttribute('aria-expanded', 'false');
    });
  });

  // ── Theme Toggle ──────────────────────────────────────────
  var themeToggle = document.getElementById('theme-toggle');
  var themeDropdown = document.getElementById('theme-dropdown');
  var themeBtn = themeToggle.querySelector('.theme-toggle-btn');

  themeBtn.addEventListener('click', function (e) {
    e.stopPropagation();
    var isOpen = themeDropdown.classList.toggle('is-open');
    themeBtn.setAttribute('aria-expanded', isOpen);
  });

  themeDropdown.querySelectorAll('.theme-option').forEach(function (opt) {
    opt.addEventListener('click', function (e) {
      e.stopPropagation();
      setTheme(opt.getAttribute('data-theme'));
      themeDropdown.classList.remove('is-open');
      themeBtn.setAttribute('aria-expanded', 'false');
    });
  });

  // Close dropdowns on outside click
  document.addEventListener('click', function (e) {
    // Close mobile menu
    if (!navToggle.contains(e.target) && !navLinks.contains(e.target)) {
      navLinks.classList.remove('open');
      navToggle.classList.remove('active');
      navToggle.setAttribute('aria-expanded', 'false');
    }
    // Close theme dropdown
    if (!themeToggle.contains(e.target)) {
      themeDropdown.classList.remove('is-open');
      themeBtn.setAttribute('aria-expanded', 'false');
    }
  });

  // ── Smooth Scroll for Anchor Links ─────────────────────────
  document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
    anchor.addEventListener('click', function (e) {
      var targetId = anchor.getAttribute('href');
      if (targetId === '#') return;
      var target = document.querySelector(targetId);
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });

  // ── Platform Detection ─────────────────────────────────────
  function detectPlatform() {
    var ua = navigator.userAgent || '';
    var platform = navigator.platform || '';
    if (/android/i.test(ua)) return 'android';
    if (/iPad|iPhone|iPod/.test(ua) || (platform === 'MacIntel' && navigator.maxTouchPoints > 1)) return 'ios';
    if (/Win/.test(platform)) return 'windows';
    if (/Mac/.test(platform)) return 'macos';
    if (/Linux/.test(platform)) return 'linux';
    return null;
  }

  var detectedPlatform = detectPlatform();

  // ── Release Data (placeholder) ─────────────────────────────
  var VERSION = '1.2.0';
  var BASE = 'https://github.com/Eoic/Papyrus/releases/download/v' + VERSION;

  // ── Platform Config ────────────────────────────────────────
  var PLATFORMS = {
    android: {
      name: 'Android',
      downloadLabel: 'Download APK',
      downloadUrl: BASE + '/papyrus-v' + VERSION + '-android-arm64.apk',
      fileName: 'papyrus-v' + VERSION + '-android-arm64.apk',
      fileSize: '48.3 MB',
      showQr: true,
      qrUrl: BASE + '/papyrus-v' + VERSION + '-android-arm64.apk',
      store: { name: 'Google Play', icon: 'fa-brands fa-google-play', url: '#' },
    },
    ios: {
      name: 'iOS',
      downloadLabel: 'Download IPA',
      downloadUrl: BASE + '/papyrus-v' + VERSION + '-ios-arm64.ipa',
      fileName: 'papyrus-v' + VERSION + '-ios-arm64.ipa',
      fileSize: '52.1 MB',
      showQr: true,
      qrUrl: BASE + '/papyrus-v' + VERSION + '-ios-arm64.ipa',
      store: { name: 'App Store', icon: 'fa-brands fa-app-store', url: '#' },
    },
    windows: {
      name: 'Windows',
      downloadLabel: 'Download ZIP',
      downloadUrl: BASE + '/papyrus-v' + VERSION + '-windows-x64.zip',
      fileName: 'papyrus-v' + VERSION + '-windows-x64.zip',
      fileSize: '62.1 MB',
      showQr: false,
      store: null,
    },
    macos: {
      name: 'macOS',
      downloadLabel: 'Download DMG',
      downloadUrl: BASE + '/papyrus-v' + VERSION + '-macos-universal.dmg',
      fileName: 'papyrus-v' + VERSION + '-macos-universal.dmg',
      fileSize: '71.4 MB',
      showQr: false,
      store: { name: 'Mac App Store', icon: 'fa-brands fa-app-store', url: '#' },
    },
    linux: {
      name: 'Linux',
      downloadLabel: 'Download tar.gz',
      downloadUrl: BASE + '/papyrus-v' + VERSION + '-linux-x64.tar.gz',
      fileName: 'papyrus-v' + VERSION + '-linux-x64.tar.gz',
      fileSize: '58.7 MB',
      showQr: false,
      store: null,
    },
    web: {
      name: 'Web',
      downloadLabel: 'Download ZIP',
      downloadUrl: BASE + '/papyrus-v' + VERSION + '-web.zip',
      fileName: 'papyrus-v' + VERSION + '-web.zip',
      fileSize: '24.5 MB',
      showQr: false,
      store: null,
    },
  };

  // ── DOM Helpers ────────────────────────────────────────────
  function el(tag, className, attrs) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (attrs) {
      Object.keys(attrs).forEach(function (k) { node.setAttribute(k, attrs[k]); });
    }
    return node;
  }

  function faIcon(classes) {
    return el('i', classes, { 'aria-hidden': 'true' });
  }

  // ── Store Badge Builder ────────────────────────────────────
  function buildStoreBadge(store) {
    if (!store) return null;
    var badge = el('a', 'platform-store-badge', { href: store.url });
    badge.appendChild(faIcon(store.icon));
    var label = document.createElement('span');
    label.textContent = store.name;
    badge.appendChild(label);
    return badge;
  }

  // ── Panel Content Builder ──────────────────────────────────
  function buildPanelEl(key) {
    var cfg = PLATFORMS[key];
    if (!cfg) return null;

    var hasQr = cfg.showQr;
    var inner = el('div', hasQr ? 'platform-details-inner platform-details-inner--with-qr' : 'platform-details-inner');

    // Left column: header + actions
    var left = el('div', 'platform-details-left');

    // Header: name + version
    var header = el('div', 'platform-details-header');
    var title = el('h3', 'platform-details-title');
    title.textContent = cfg.name;
    header.appendChild(title);
    var ver = el('span', 'platform-details-version');
    ver.textContent = 'v' + VERSION;
    header.appendChild(ver);
    left.appendChild(header);

    // Action buttons in a row + meta below
    var actions = el('div', 'platform-details-actions');

    var actionsRow = el('div', 'platform-actions-row');

    var dlBtn = el('a', 'platform-download-btn', { href: cfg.downloadUrl, download: '' });
    dlBtn.appendChild(faIcon('fa-solid fa-download'));
    var dlSpan = document.createElement('span');
    dlSpan.textContent = cfg.downloadLabel;
    dlBtn.appendChild(dlSpan);
    actionsRow.appendChild(dlBtn);

    var storeBadge = buildStoreBadge(cfg.store);
    if (storeBadge) actionsRow.appendChild(storeBadge);

    actions.appendChild(actionsRow);

    var meta = el('span', 'platform-download-meta');
    meta.textContent = cfg.fileName + '  \u00B7  ' + cfg.fileSize;
    actions.appendChild(meta);

    left.appendChild(actions);
    inner.appendChild(left);

    // Right column: QR code (full height)
    if (hasQr) {
      var qrWrap = el('div', 'platform-details-qr');
      var qrBox = el('div', 'platform-qr-code', { 'data-qr-target': key });
      qrWrap.appendChild(qrBox);
      var qrLabel = el('span', 'platform-qr-label');
      qrLabel.textContent = 'Scan to download';
      qrWrap.appendChild(qrLabel);
      inner.appendChild(qrWrap);
    }

    return inner;
  }

  // ── QR Code Generation ─────────────────────────────────────
  function generateQrCode(key) {
    if (typeof QRCodeStyling === 'undefined') return;

    var cfg = PLATFORMS[key];
    if (!cfg || !cfg.qrUrl) return;

    var container = document.querySelector('.platform-qr-code[data-qr-target="' + key + '"]');
    if (!container) return;

    var theme = getCurrentTheme();
    var dotColor = THEMES[theme] ? THEMES[theme].qrDot : '#2D2A26';

    var qr = new QRCodeStyling({
      width: 140,
      height: 140,
      type: 'svg',
      data: cfg.qrUrl,
      dotsOptions: {
        color: dotColor,
        type: 'rounded',
      },
      backgroundOptions: {
        color: '#FFFFFF',
      },
      cornersSquareOptions: {
        type: 'extra-rounded',
      },
      cornersDotOptions: {
        type: 'dot',
      },
      qrOptions: {
        errorCorrectionLevel: 'M',
      },
    });

    qr.append(container);
  }

  // ── Accordion Logic (instant, no animation) ────────────────
  var detailsPanel = document.getElementById('platform-details');
  var platformCards = document.querySelectorAll('.platform-card[data-platform]');
  var currentPlatform = null;

  function collapsePanel() {
    if (!currentPlatform) return;
    var card = document.querySelector('.platform-card[data-platform="' + currentPlatform + '"]');
    if (card) card.setAttribute('aria-expanded', 'false');
    detailsPanel.classList.remove('is-open');
    detailsPanel.setAttribute('hidden', '');
    while (detailsPanel.firstChild) detailsPanel.removeChild(detailsPanel.firstChild);
    currentPlatform = null;
  }

  function clearDetectedHighlight() {
    platformCards.forEach(function (c) {
      c.classList.remove('platform-card--detected');
    });
  }

  function expandPlatform(key) {
    // Clear auto-detected highlight on any interaction
    clearDetectedHighlight();

    // Toggle off if same
    if (currentPlatform === key) {
      collapsePanel();
      return;
    }

    // Collapse current if open
    if (currentPlatform) collapsePanel();

    currentPlatform = key;
    var content = buildPanelEl(key);
    if (content) detailsPanel.appendChild(content);
    detailsPanel.removeAttribute('hidden');
    detailsPanel.classList.add('is-open');

    // Update aria
    var card = document.querySelector('.platform-card[data-platform="' + key + '"]');
    if (card) card.setAttribute('aria-expanded', 'true');

    // QR code
    if (PLATFORMS[key] && PLATFORMS[key].showQr) {
      generateQrCode(key);
    }
  }

  // Click handlers
  platformCards.forEach(function (card) {
    card.addEventListener('click', function () {
      expandPlatform(card.getAttribute('data-platform'));
    });
  });

  // ── Init ───────────────────────────────────────────────────
  // Apply stored theme and mark active dropdown option
  var storedTheme = getCurrentTheme();
  document.querySelectorAll('.theme-option').forEach(function (opt) {
    opt.classList.toggle('is-active', opt.getAttribute('data-theme') === storedTheme);
  });

  if (detectedPlatform) {
    platformCards.forEach(function (card) {
      if (card.getAttribute('data-platform') === detectedPlatform) {
        card.classList.add('platform-card--detected');
      }
    });
    expandPlatform(detectedPlatform);
  }
})();
