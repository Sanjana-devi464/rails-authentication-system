import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["stats", "activities", "notifications"]

  connect() {
    console.log("Dashboard controller connected")
  }

  refresh(event) {
    event.preventDefault()
    const button = event.currentTarget
    const originalContent = button.innerHTML
    
    // Show loading state
    button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Refreshing...'
    button.disabled = true
    
    // Fetch fresh data
    fetch('/dashboard/quick_stats')
      .then(response => response.json())
      .then(data => {
        this.updateStats(data)
        this.showSuccessMessage()
      })
      .catch(error => {
        console.error('Error refreshing dashboard:', error)
        this.showErrorMessage()
      })
      .finally(() => {
        // Reset button
        button.innerHTML = originalContent
        button.disabled = false
      })
  }

  updateStats(data) {
    // Update profile completion
    const profileElement = document.getElementById('stat-profile_completion')
    if (profileElement && data.profile_completion !== undefined) {
      profileElement.textContent = data.profile_completion + '%'
    }

    // Update notifications count
    const notificationsElement = document.getElementById('stat-unread_notifications')
    if (notificationsElement && data.unread_notifications !== undefined) {
      notificationsElement.textContent = data.unread_notifications
    }

    // Update other stats if available
    if (data.recent_activities && data.recent_activities.length > 0) {
      this.updateRecentActivities(data.recent_activities)
    }
  }

  updateRecentActivities(activities) {
    const activitiesContainer = document.querySelector('.activity-timeline')
    if (activitiesContainer && activities.length > 0) {
      const activitiesHtml = activities.map(activity => `
        <div class="activity-item d-flex align-items-start mb-3">
          <div class="activity-icon me-3">
            <i class="fas fa-clock fa-sm"></i>
          </div>
          <div class="activity-content flex-grow-1">
            <div class="activity-description">${activity}</div>
            <div class="activity-time text-muted small">Just now</div>
          </div>
        </div>
      `).join('')
      
      activitiesContainer.innerHTML = activitiesHtml
    }
  }

  showSuccessMessage() {
    this.showMessage('Dashboard refreshed successfully!', 'success')
  }

  showErrorMessage() {
    this.showMessage('Failed to refresh dashboard', 'danger')
  }

  showMessage(message, type) {
    // Create and show a temporary alert
    const alert = document.createElement('div')
    alert.className = `alert alert-${type} alert-dismissible fade show position-fixed`
    alert.style.cssText = 'top: 20px; right: 20px; z-index: 1050; min-width: 300px;'
    alert.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `
    
    document.body.appendChild(alert)
    
    // Auto-remove after 3 seconds
    setTimeout(() => {
      if (alert.parentNode) {
        alert.remove()
      }
    }, 3000)
  }
}
