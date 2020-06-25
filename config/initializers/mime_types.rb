# Be sure to restart your server when you modify this file.
require 'mimemagic'
require 'mimemagic/overlay'

MimeMagic.add(
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  magic: [[0, "PK\003\004", [[0..5000, '[Content_Types].xml', [[0..5000, 'ppt/']]]]]],
  extensions: %w[pptx],
  parents: %w[application/zip],
  comment: 'PowerPoint 2007 document'
)
MimeMagic.add(
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  magic: [[0, "PK\003\004", [[0..5000, '[Content_Types].xml', [[0..5000, 'xl/']]]]]],
  extensions: %w[xlsx],
  parents: %w[application/zip],
  comment: 'Excel 2007 document'
)
MimeMagic.add(
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  magic: [[0, "PK\003\004", [[0..5000, '[Content_Types].xml', [[0..5000, 'word/']]]]]],
  extensions: %w[docx],
  parents: %w[application/zip],
  comment: 'Word 2007 document'
)
# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
