/* Papyrus Documentation - Custom JavaScript */

// Initialize any custom functionality after page load
document.addEventListener('DOMContentLoaded', function() {
  // Add external link indicators
  document.querySelectorAll('a[href^="http"]').forEach(function(link) {
    if (!link.hostname.includes(window.location.hostname)) {
      link.setAttribute('target', '_blank');
      link.setAttribute('rel', 'noopener noreferrer');
    }
  });
});
