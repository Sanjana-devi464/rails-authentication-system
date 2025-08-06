// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "stimulus-loading"
import "trix"

// Ensure Trix is ready
document.addEventListener('DOMContentLoaded', function() {
  console.log('DOM loaded, Trix should be available')
  
  // Add global Trix event listeners for debugging
  document.addEventListener('trix-initialize', function(event) {
    console.log('Trix editor initialized:', event.target)
  })
  
  document.addEventListener('trix-change', function(event) {
    console.log('Trix content changed')
  })
})
