import './../styles/main.css';

// Entry point - import components and init on DOMContentLoaded.
// Heavy components (Three.js, QR) must stay behind dynamic import() +
// IntersectionObserver. Every init returns a cleanup function.

const cleanups = [];

function init() {
  const prefersReduced = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches;

  // const cleanupHero = initHero();
  // if ( cleanupHero ) cleanups.push( cleanupHero );
}

// Teardown hook for swup content:replace or page transitions.
export function teardown() {
  cleanups.forEach((cleanup) => cleanup());
  cleanups.length = 0;
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
