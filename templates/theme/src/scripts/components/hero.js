import gsap from 'gsap';
import Tempus from 'tempus';

// Example component: hero intro + parallax.
// House pattern: element guard -> reduced-motion gate -> gsap.context()
// animations scoped to the component -> Tempus frame loop -> cleanup
// function returned for teardown (swup content:replace, page transitions).
export function initHero() {
  const el = document.querySelector('[data-hero]');
  if (!el) return;

  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  const ctx = gsap.context(() => {
    gsap.fromTo(
      '.hero__title, .hero__content',
      { opacity: 0, y: 24 },
      { opacity: 1, y: 0, duration: 0.6, stagger: 0.12, ease: 'power2.out' }
    );
  }, el);

  // Frame work example: parallax. Runs at order -1 (before render-order
  // callbacks) so its read of scroll never interleaves with other writes.
  // NOTE: use + concatenation here - template-literal interpolation is
  // flagged as a stray token by the scaffold dry-run guard.
  const unsubscribe = Tempus.add(
    () => {
      const parallax = Math.round(window.scrollY * 0.25);
      el.style.transform = 'translate3d(0, ' + parallax + 'px, 0)';
    },
    { order: -1 }
  );

  return () => {
    ctx.revert();
    unsubscribe();
  };
}
