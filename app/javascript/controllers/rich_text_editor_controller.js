import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editor", "input", "showingCount"]
  
  connect() {
    console.log('Rich text editor controller connected')
    this.bindEvents()
  }
  
  bindEvents() {
    // Wait for Trix to be ready
    this.editorTarget.addEventListener('trix-initialize', () => {
      console.log('Trix editor initialized')
      this.loadInitialContent()
      this.updateStats()
    })

    // Listen for content changes
    this.editorTarget.addEventListener('trix-change', () => {
      this.syncToHiddenField()
      this.updateStats()
      this.updatePreview()
    })
  }
  
  loadInitialContent() {
    if (this.hasInputTarget && this.inputTarget.value && this.editorTarget.editor) {
      this.editorTarget.editor.loadHTML(this.inputTarget.value)
    }
  }
  
  syncToHiddenField() {
    if (this.hasInputTarget && this.editorTarget.editor) {
      this.inputTarget.value = this.editorTarget.innerHTML
    }
  }
  
  updateStats() {
    if (!this.hasShowingCountTarget || !this.editorTarget.editor) return
    
    try {
      const text = this.editorTarget.editor.getDocument().toString()
      const wordCount = text.trim().split(/\s+/).filter(word => word.length > 0).length
      const charCount = text.length
      const readingTime = Math.ceil(wordCount / 200) || 1
      
      this.showingCountTarget.textContent = `${charCount} characters | ${wordCount} words | ${readingTime} min read`
    } catch (error) {
      console.warn('Stats update failed:', error)
    }
  }

  updatePreview() {
    try {
      const previewBody = document.getElementById('preview-body')
      if (previewBody && this.editorTarget.editor) {
        const htmlContent = this.editorTarget.editor.getDocument().toString()
        const richContent = this.editorTarget.innerHTML
        
        if (htmlContent.trim()) {
          previewBody.innerHTML = richContent
          previewBody.className = 'text-dark rich-text-preview'
        } else {
          previewBody.textContent = 'Enter content to see preview...'
          previewBody.className = 'text-muted rich-text-preview'
        }
      }
    } catch (error) {
      console.warn('Preview update failed:', error)
    }
  }
}