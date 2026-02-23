/**
 * Papyrus Landing Page — Interactions
 *
 * - Navbar scroll behavior (background on scroll)
 * - Mobile menu toggle
 * - Smooth scrolling for anchor links
 * - Platform detection for download CTAs
 */

(function () {
  'use strict';

  // ── Navbar Scroll ──────────────────────────────────────────
  const nav = document.getElementById('nav');

  function onScroll() {
    nav.classList.toggle('scrolled', window.scrollY > 20);
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll(); // Initial check

  // ── Mobile Menu ────────────────────────────────────────────
  const navToggle = document.getElementById('nav-toggle');
  const navLinks = document.getElementById('nav-links');

  navToggle.addEventListener('click', () => {
    const isOpen = navLinks.classList.toggle('open');
    navToggle.classList.toggle('active', isOpen);
    navToggle.setAttribute('aria-expanded', isOpen);
  });

  // Close mobile menu on link click
  navLinks.querySelectorAll('.nav-link').forEach((link) => {
    link.addEventListener('click', () => {
      navLinks.classList.remove('open');
      navToggle.classList.remove('active');
      navToggle.setAttribute('aria-expanded', 'false');
    });
  });

  // Close mobile menu on outside click
  document.addEventListener('click', (e) => {
    if (!navToggle.contains(e.target) && !navLinks.contains(e.target)) {
      navLinks.classList.remove('open');
      navToggle.classList.remove('active');
      navToggle.setAttribute('aria-expanded', 'false');
    }
  });

  // ── Smooth Scroll for Anchor Links ─────────────────────────
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

  // ── Platform Detection ─────────────────────────────────────
  function detectPlatform() {
    const ua = navigator.userAgent || '';
    const platform = navigator.platform || '';

    if (/android/i.test(ua)) return 'Android';
    if (/iPad|iPhone|iPod/.test(ua) || (platform === 'MacIntel' && navigator.maxTouchPoints > 1)) return 'iOS';
    if (/Win/.test(platform)) return 'Windows';
    if (/Mac/.test(platform)) return 'macOS';
    if (/Linux/.test(platform)) return 'Linux';
    return null;
  }

  const detectedPlatform = detectPlatform();

  if (detectedPlatform) {
    // Highlight the detected platform card
    document.querySelectorAll('.platform-card').forEach((card) => {
      const name = card.querySelector('.platform-name');
      if (name && name.textContent.trim() === detectedPlatform) {
        card.classList.add('platform-card--detected');
      }
    });
  }
})();
