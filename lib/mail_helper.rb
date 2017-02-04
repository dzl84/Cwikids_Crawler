require 'mail'
require 'yaml'
require 'logging'

class MailHelper
  USE_SMTP = true

  DEFAULT_SUBJECT = 'No subject'
  DEFAULT_BODY = 'No email body'

  CONFIG_PATH = "../config/mail_config.yml"

  def initialize
    @logger = Logging.logger(STDOUT)
    config_file = File.join(File.dirname(__FILE__), CONFIG_PATH)
    config = YAML.load(File.read(config_file))
    @default_from = config["default_from"]
    @default_to = config["default_to"]

    Mail.defaults do
      delivery_method :smtp,
                      address: config["server"], port: config["port"],
                      user_name: config["username"], password: config["password"]
    end if USE_SMTP

  end

  def send (opts)
    @logger.info("Sending email.")
    from_user = opts[:from] || @default_from
    to_user = opts[:to] || @default_to
    subject_str = opts[:subject] || DEFAULT_SUBJECT
    body_str = opts[:body] || DEFAULT_BODY

    mail = Mail.new do
      from     from_user
      to       to_user
      subject  subject_str
      body     body_str
    end

    mail.deliver!
    @logger.info("Email sent.")
  end
end