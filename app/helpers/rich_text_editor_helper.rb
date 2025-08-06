module RichTextEditorHelper
  def rich_text_editor_for(form, attribute, options = {})
    # Default options
    default_options = {
      placeholder: "Write your content here...",
      toolbar: true,
      stats: true,
      preview: false,
      height: "300px"
    }
    
    options = default_options.merge(options)
    
    # Generate unique IDs
    editor_id = "#{form.object.class.name.downcase}_#{attribute}"
    container_class = "rich-text-container"
    container_class += " is-invalid" if form.object.errors[attribute].any?
    
    content_tag :div, class: container_class, data: { controller: "rich-text-editor" } do
      concat form.hidden_field(attribute, data: { "rich-text-editor-target": "input" })
      concat content_tag(:trix_editor, 
        form.object.send(attribute)&.html_safe,
        input: "#{editor_id}",
        data: { "rich-text-editor-target": "editor" },
        placeholder: options[:placeholder],
        class: "trix-content",
        style: "min-height: #{options[:height]};"
      )
    end
  end
  
  def rich_text_stats_for(form, attribute)
    content_tag :div, class: "form-text" do
      concat content_tag(:small, class: "text-muted") do
        concat content_tag(:i, "", class: "fas fa-info-circle me-1")
        concat content_tag(:span, 
          "0 characters | 0 words | 0 min read", 
          data: { "rich-text-editor-target": "showingCount" }
        )
      end
      concat content_tag(:small, class: "text-muted d-block mt-1") do
        concat "💡 "
        concat content_tag(:strong, "Formatting Tips:")
        concat " Use "
        concat content_tag(:kbd, "Ctrl+B")
        concat " for bold, "
        concat content_tag(:kbd, "Ctrl+I") 
        concat " for italic, "
        concat content_tag(:kbd, "Ctrl+U")
        concat " for underline, "
        concat content_tag(:kbd, "Ctrl+K")
        concat " for links"
      end
    end
  end
  
  def rich_text_preview_section(title_id = "preview-title", body_id = "preview-body")
    content_tag :div, class: "mb-4" do
      concat content_tag(:button, 
        type: "button", 
        class: "btn btn-outline-info btn-sm",
        data: { "bs-toggle": "collapse", "bs-target": "#preview" }
      ) do
        concat content_tag(:i, "", class: "fas fa-eye me-1")
        concat "Toggle Preview"
      end
      
      concat content_tag(:div, class: "collapse mt-3", id: "preview") do
        content_tag :div, class: "card bg-light" do
          concat content_tag(:div, class: "card-header d-flex justify-content-between align-items-center") do
            concat content_tag(:h6, class: "mb-0") do
              concat content_tag(:i, "", class: "fas fa-eye me-1")
              concat "Live Preview"
            end
            concat content_tag(:small, "How your content will appear", class: "text-muted")
          end
          
          concat content_tag(:div, class: "card-body") do
            concat content_tag(:h5, "Enter a title to see preview...", 
              id: title_id, class: "text-muted mb-3")
            concat content_tag(:div, "Enter content to see preview...", 
              id: body_id, class: "text-muted rich-text-preview")
          end
        end
      end
    end
  end
end
