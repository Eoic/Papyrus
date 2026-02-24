/**
 * - Navbar scroll behavior
 * - Mobile menu toggle
 * - Smooth scrolling for anchor links
 * - Theme switching with localStorage persistence
 * - Platform detection & auto-expand
 * - Platform accordion with direct downloads, QR codes & store badges
 */

(() => {
  'use strict';

  const THEMES = {
    'light-gold': { metaColor: '#FDFAF5', qrDot: '#2D2A26' },
    'dark-gold': { metaColor: '#1A1814', qrDot: '#2D2A26' },
    'light-purple': { metaColor: '#FAFAFE', qrDot: '#1C1B1F' },
    'dark-purple': { metaColor: '#151318', qrDot: '#1C1B1F' },
  };

  const DEFAULT_THEME = 'light-gold';
  const VERSION = '1.2.0';
  const BASE = `https://github.com/Eoic/Papyrus/releases/download/v${VERSION}`;

  const PLATFORMS = {
    android: {
      name: 'Android',
      downloadLabel: 'Download APK',
      downloadUrl: `${BASE}/papyrus-v${VERSION}-android-arm64.apk`,
      fileName: `papyrus-v${VERSION}-android-arm64.apk`,
      fileSize: '48.3 MB',
      showQr: true,
      qrUrl: `${BASE}/papyrus-v${VERSION}-android-arm64.apk`,
      store: { name: 'Google Play', icon: 'fa-brands fa-google-play', url: '#' },
    },
    ios: {
      name: 'iOS',
      downloadLabel: 'Download IPA',
      downloadUrl: `${BASE}/papyrus-v${VERSION}-ios-arm64.ipa`,
      fileName: `papyrus-v${VERSION}-ios-arm64.ipa`,
      fileSize: '52.1 MB',
      showQr: true,
      qrUrl: `${BASE}/papyrus-v${VERSION}-ios-arm64.ipa`,
      store: { name: 'App Store', icon: 'fa-brands fa-app-store', url: '#' },
    },
    windows: {
      name: 'Windows',
      downloadLabel: 'Download ZIP',
      downloadUrl: `${BASE}/papyrus-v${VERSION}-windows-x64.zip`,
      fileName: `papyrus-v${VERSION}-windows-x64.zip`,
      fileSize: '62.1 MB',
      showQr: false,
      store: null,
    },
    macos: {
      name: 'macOS',
      downloadLabel: 'Download DMG',
      downloadUrl: `${BASE}/papyrus-v${VERSION}-macos-universal.dmg`,
      fileName: `papyrus-v${VERSION}-macos-universal.dmg`,
      fileSize: '71.4 MB',
      showQr: false,
      store: { name: 'Mac App Store', icon: 'fa-brands fa-app-store', url: '#' },
    },
    linux: {
      name: 'Linux',
      downloadLabel: 'Download tar.gz',
      downloadUrl: `${BASE}/papyrus-v${VERSION}-linux-x64.tar.gz`,
      fileName: `papyrus-v${VERSION}-linux-x64.tar.gz`,
      fileSize: '58.7 MB',
      showQr: false,
      store: null,
    },
    web: {
      name: 'Web',
      downloadLabel: 'Download ZIP',
      downloadUrl: `${BASE}/papyrus-v${VERSION}-web.zip`,
      fileName: `papyrus-v${VERSION}-web.zip`,
      fileSize: '24.5 MB',
      showQr: false,
      store: null,
    },
  };

  const getCurrentTheme = () =>
    document.documentElement.getAttribute('data-theme') ?? DEFAULT_THEME;

  const setTheme = (theme) => {
    if (!THEMES[theme]) return;

    document.documentElement.setAttribute('data-theme-transitioning', '');
    document.documentElement.setAttribute('data-theme', theme);

    document.getElementById('meta-theme-color')
      ?.setAttribute('content', THEMES[theme].metaColor);

    try { localStorage.setItem('papyrus-theme', theme); } catch { }

    document.querySelectorAll('.theme-option').forEach((opt) => {
      opt.classList.toggle('is-active', opt.getAttribute('data-theme') === theme);
    });

    setTimeout(() => {
      document.documentElement.removeAttribute('data-theme-transitioning');
    }, 350);

    if (currentPlatform && PLATFORMS[currentPlatform]?.showQr) {
      const container = document.querySelector(`.platform-qr-code[data-qr-target="${currentPlatform}"]`);
      if (container) {
        container.replaceChildren();
        generateQrCode(currentPlatform);
      }
    }
  };

  const detectPlatform = () => {
    const ua = navigator.userAgent ?? '';
    const platform = navigator.platform ?? '';
    if (/android/i.test(ua)) return 'android';
    if (/iPad|iPhone|iPod/.test(ua) || (platform === 'MacIntel' && navigator.maxTouchPoints > 1)) return 'ios';
    if (/Win/.test(platform)) return 'windows';
    if (/Mac/.test(platform)) return 'macos';
    if (/Linux/.test(platform)) return 'linux';
    return null;
  };

  const el = (tag, className, attrs) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (attrs) {
      Object.keys(attrs).forEach((k) => node.setAttribute(k, attrs[k]));
    }
    return node;
  };

  const faIcon = (classes) => el('i', classes, { 'aria-hidden': 'true' });

  const nav = document.getElementById('nav');
  const navToggle = document.getElementById('nav-toggle');
  const navLinks = document.getElementById('nav-links');
  const themeToggle = document.getElementById('theme-toggle');
  const themeDropdown = document.getElementById('theme-dropdown');
  const themeBtn = themeToggle.querySelector('.theme-toggle-btn');
  const detailsPanel = document.getElementById('platform-details');
  const platformCards = document.querySelectorAll('.platform-card[data-platform]');
  const detectedPlatform = detectPlatform();
  let currentPlatform = null;

  const buildStoreBadge = (store) => {
    if (!store) return null;
    const badge = el('a', 'platform-store-badge', { href: store.url });
    badge.appendChild(faIcon(store.icon));
    const label = document.createElement('span');
    label.textContent = store.name;
    badge.appendChild(label);
    return badge;
  };

  const buildPanelEl = (key) => {
    const cfg = PLATFORMS[key];
    if (!cfg) return null;

    const inner = el('div', cfg.showQr
      ? 'platform-details-inner platform-details-inner--with-qr'
      : 'platform-details-inner');

    const left = el('div', 'platform-details-left');

    const header = el('div', 'platform-details-header');
    const title = el('h3', 'platform-details-title');
    title.textContent = cfg.name;
    header.appendChild(title);
    const ver = el('span', 'platform-details-version');
    ver.textContent = `v${VERSION}`;
    header.appendChild(ver);
    left.appendChild(header);

    const actions = el('div', 'platform-details-actions');
    const actionsRow = el('div', 'platform-actions-row');

    const dlBtn = el('a', 'platform-download-btn', { href: cfg.downloadUrl, download: '' });
    dlBtn.appendChild(faIcon('fa-solid fa-download'));
    const dlSpan = document.createElement('span');
    dlSpan.textContent = cfg.downloadLabel;
    dlBtn.appendChild(dlSpan);
    actionsRow.appendChild(dlBtn);

    const storeBadge = buildStoreBadge(cfg.store);
    if (storeBadge) actionsRow.appendChild(storeBadge);

    actions.appendChild(actionsRow);

    const meta = el('span', 'platform-download-meta');
    meta.textContent = `${cfg.fileName}  \u00B7  ${cfg.fileSize}`;
    actions.appendChild(meta);

    left.appendChild(actions);
    inner.appendChild(left);

    if (cfg.showQr) {
      const qrWrap = el('div', 'platform-details-qr');
      const qrBox = el('div', 'platform-qr-code', { 'data-qr-target': key });
      qrWrap.appendChild(qrBox);
      const qrLabel = el('span', 'platform-qr-label');
      qrLabel.textContent = 'Scan to download';
      qrWrap.appendChild(qrLabel);
      inner.appendChild(qrWrap);
    }

    return inner;
  };

  const generateQrCode = (key) => {
    if (typeof QRCodeStyling === 'undefined') return;

    const cfg = PLATFORMS[key];
    if (!cfg?.qrUrl) return;

    const container = document.querySelector(`.platform-qr-code[data-qr-target="${key}"]`);
    if (!container) return;

    const theme = getCurrentTheme();
    const { qrDot } = THEMES[theme] ?? {};

    const qr = new QRCodeStyling({
      width: 140,
      height: 140,
      type: 'svg',
      data: cfg.qrUrl,
      dotsOptions: { color: qrDot ?? '#2D2A26', type: 'rounded' },
      backgroundOptions: { color: '#FFFFFF' },
      cornersSquareOptions: { type: 'extra-rounded' },
      cornersDotOptions: { type: 'dot' },
      qrOptions: { errorCorrectionLevel: 'M' },
    });

    qr.append(container);
  };

  const collapsePanel = () => {
    if (!currentPlatform) return;

    document.querySelector(`.platform-card[data-platform="${currentPlatform}"]`)
      ?.setAttribute('aria-expanded', 'false');

    detailsPanel.classList.remove('is-open');
    detailsPanel.setAttribute('hidden', '');
    detailsPanel.replaceChildren();
    currentPlatform = null;
  };

  const clearDetectedHighlight = () => {
    platformCards.forEach((c) => c.classList.remove('platform-card--detected'));
  };

  const expandPlatform = (key) => {
    clearDetectedHighlight();

    if (currentPlatform === key) {
      collapsePanel();
      return;
    }

    if (currentPlatform) collapsePanel();

    currentPlatform = key;
    const content = buildPanelEl(key);
    if (content) detailsPanel.appendChild(content);
    detailsPanel.removeAttribute('hidden');
    detailsPanel.classList.add('is-open');

    document.querySelector(`.platform-card[data-platform="${key}"]`)
      ?.setAttribute('aria-expanded', 'true');

    if (PLATFORMS[key]?.showQr) {
      generateQrCode(key);
    }
  };

  const onScroll = () => nav.classList.toggle('scrolled', window.scrollY > 20);
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  navToggle.addEventListener('click', () => {
    const isOpen = navLinks.classList.toggle('open');
    navToggle.classList.toggle('active', isOpen);
    navToggle.setAttribute('aria-expanded', isOpen);
  });

  navLinks.querySelectorAll('.nav-link').forEach((link) => {
    link.addEventListener('click', () => {
      navLinks.classList.remove('open');
      navToggle.classList.remove('active');
      navToggle.setAttribute('aria-expanded', 'false');
    });
  });

  themeBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    const isOpen = themeDropdown.classList.toggle('is-open');
    themeBtn.setAttribute('aria-expanded', isOpen);
  });

  themeDropdown.querySelectorAll('.theme-option').forEach((opt) => {
    opt.addEventListener('click', (e) => {
      e.stopPropagation();
      setTheme(opt.getAttribute('data-theme'));
      themeDropdown.classList.remove('is-open');
      themeBtn.setAttribute('aria-expanded', 'false');
    });
  });

  document.addEventListener('click', (e) => {
    if (!navToggle.contains(e.target) && !navLinks.contains(e.target)) {
      navLinks.classList.remove('open');
      navToggle.classList.remove('active');
      navToggle.setAttribute('aria-expanded', 'false');
    }

    if (!themeToggle.contains(e.target)) {
      themeDropdown.classList.remove('is-open');
      themeBtn.setAttribute('aria-expanded', 'false');
    }
  });

  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener('click', (e) => {
      const targetId = anchor.getAttribute('href');
      if (targetId === '#') return;
      const target = document.querySelector(targetId);
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });

  platformCards.forEach((card) => {
    card.addEventListener('click', () => {
      expandPlatform(card.getAttribute('data-platform'));
    });
  });

  const storedTheme = getCurrentTheme();
  document.querySelectorAll('.theme-option').forEach((opt) => {
    opt.classList.toggle('is-active', opt.getAttribute('data-theme') === storedTheme);
  });

  if (detectedPlatform) {
    platformCards.forEach((card) => {
      if (card.getAttribute('data-platform') === detectedPlatform) {
        card.classList.add('platform-card--detected');
      }
    });
    expandPlatform(detectedPlatform);
  }
})();
