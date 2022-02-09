erica_host = ENV['ERICA_HOST'] || "localhost:3000";
protocol = Rails.env.production? ? "https" : "http"

Grover.configure do |config|
  config.options = {
    format: 'A4',
    display_url: "#{protocol}://#{erica_host}",
    margin: {
      top: '1cm',
      left: '1cm',
      right: '1cm',
      bottom: '2cm'
    },
    launch_args: ['--no-sandbox', '--disable-setuid-sandbox'] }
end
