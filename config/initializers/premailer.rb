Premailer::Rails.config.merge!(
  preserve_styles: true,
  remove_ids: true,
  generate_text_part: false,
  adapter: 'nokogiri'
)
