// PromptReel AI — Website JS
// chAs Tech Group · 2025

(function () {
  'use strict';

  // ── Navbar scroll effect ────────────────────────────────────────────────
  const navbar = document.getElementById('navbar');
  window.addEventListener('scroll', () => {
    navbar.classList.toggle('scrolled', window.scrollY > 40);
  }, { passive: true });

  // ── Mobile hamburger menu ───────────────────────────────────────────────
  const hamburger   = document.getElementById('hamburger');
  const mobileMenu  = document.getElementById('mobileMenu');

  hamburger.addEventListener('click', () => {
    mobileMenu.classList.toggle('open');
  });

  // Close mobile menu when a link is clicked
  mobileMenu.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => mobileMenu.classList.remove('open'));
  });

  // ── Smooth scroll for anchor links ─────────────────────────────────────
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', e => {
      const target = document.querySelector(anchor.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });

  // ── Intersection Observer for scroll-in animations ──────────────────────
  const observerOptions = { threshold: 0.12, rootMargin: '0px 0px -40px 0px' };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.style.opacity = '1';
        entry.target.style.transform = 'translateY(0)';
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  document.querySelectorAll('.feature-card, .step, .pricing-card, .tier-card').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
    observer.observe(el);
  });

  // Add staggered delays to grids
  document.querySelectorAll('.features-grid .feature-card, .pricing-grid .pricing-card, .models-grid .tier-card').forEach((el, i) => {
    el.style.transitionDelay = `${i * 80}ms`;
  });

  // ── Active nav link on scroll ───────────────────────────────────────────
  const sections = document.querySelectorAll('section[id]');
  const navLinks  = document.querySelectorAll('.nav__links a');

  window.addEventListener('scroll', () => {
    let current = '';
    sections.forEach(section => {
      if (window.scrollY >= section.offsetTop - 100) {
        current = section.getAttribute('id');
      }
    });

    navLinks.forEach(link => {
      link.style.color = link.getAttribute('href') === `#${current}`
        ? 'var(--text-primary)'
        : '';
    });
  }, { passive: true });

  // ── Typing animation for hero ───────────────────────────────────────────
  const inputText = document.querySelector('.input-text');
  if (inputText) {
    const phrases = [
      'A short horror story set in a lighthouse...',
      'Top 10 AI tools for content creators...',
      'Documentary on ancient Egyptian engineering...',
      'My morning routine that changed my life...',
      'Funny cat fails compilation narration...',
    ];
    let phraseIdx = 0;
    let charIdx   = 0;
    let deleting  = false;
    let pausing   = false;

    function typeLoop() {
      const phrase = phrases[phraseIdx];

      if (pausing) {
        pausing = false;
        deleting = true;
        setTimeout(typeLoop, 1400);
        return;
      }

      if (!deleting) {
        inputText.textContent = phrase.slice(0, charIdx + 1);
        charIdx++;
        if (charIdx === phrase.length) {
          pausing = true;
          setTimeout(typeLoop, 2200);
          return;
        }
        setTimeout(typeLoop, 45 + Math.random() * 30);
      } else {
        inputText.textContent = phrase.slice(0, charIdx - 1);
        charIdx--;
        if (charIdx === 0) {
          deleting = false;
          phraseIdx = (phraseIdx + 1) % phrases.length;
          setTimeout(typeLoop, 400);
          return;
        }
        setTimeout(typeLoop, 22);
      }
    }

    setTimeout(typeLoop, 1200);
  }

  // ── PWA install prompt ──────────────────────────────────────────────────
  let deferredPrompt;
  window.addEventListener('beforeinstallprompt', e => {
    e.preventDefault();
    deferredPrompt = e;
  });

  console.log('%c🎬 PromptReel AI', 'color:#ffb830;font-size:20px;font-weight:bold;');
  console.log('%cMade with ❤️ by chAs Tech Group', 'color:#9999c0;font-size:13px;');
})();
