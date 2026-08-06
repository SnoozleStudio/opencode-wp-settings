import './../styles/main.css';
import { initHero } from './components/hero';

// Entry point - import components and init on DOMContentLoaded.
// Every init returns a cleanup function; components gate themselves
// on element existence and prefers-reduced-motion.

const cleanups = [];

function init() {
  const cleanupHero = initHero();
  if (cleanupHero) cleanups.push(cleanupHero);
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
