module VcrHelperMethods

  def filter_rails_secret(path_to_secret)
    secret_name = path_to_secret.join("_")

    secret_value = Rails.application.secrets
    path_to_secret.each do |key|
      secret_value = secret_value[key]
    end

    filter_value(value: secret_value, with: secret_name)
  end

  def filter_env_var(env_var_name)
    filter_value(value: ENV[env_var_name], with: env_var_name)
  end

  def filter_value(value:, with:)
    VCR.configure do |c|
      if value.present?
        c.filter_sensitive_data("#{with}") { value }

        # If the secret value is a URL, it may be used without its protocol
        if value.starts_with?("http")
          value_without_protocol = value.sub(/^https?\:\/\//,'')
          c.filter_sensitive_data("#{with}_without_protocol") { value_without_protocol }
        end

        # If the secret value is inside a URL, it will be URL encoded which means it
        # may be different from value.  Handle this.
        url_value = CGI::escape(value.to_s)
        if value != url_value
          c.filter_sensitive_data("#{with}_url") { url_value }
        end
      end
    end
  end

  def vcr_friendly_uuids(count:, namespace: '')
    uuids = count.times.map{ SecureRandom.uuid }
    VCR.configure do |config|
      uuids.each_with_index{|uuid,ii| config.define_cassette_placeholder("<UUID_#{namespace}_#{ii}>") { uuid }}
    end
    uuids
  end

end
