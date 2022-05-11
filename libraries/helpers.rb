module VenafiCookbook
  module Helper
    extend Chef::Mixin::ShellOut

    def version
      '4.19.0'
    end

    def version_specific
      '4.19.0'
    end

    def platform
      'linux86'
    end

    def venafi_download_url
      "https://github.com/Venafi/vcert/releases/download/v#{version}/vcert-v#{version_specific}_#{platform}"
    end

    def venafi_install_path
      '/usr/local/bin/vcert'
    end

    def enroll(apikey:, zone:, cert_path:, key_path:, chain_path:, common_name:, id_path:, tpp_username:, tpp_password:, token:, tpp_url:, instance:, app_info:, tls_address:)
      cmd = "#{venafi_install_path} enroll -no-prompt"
      cmd << " -k '#{apikey}'" if apikey
      cmd << " -tpp-user '#{tpp_username}' -tpp-password '#{tpp_password}'" if !token
      cmd << " -t '#{token}'" if token
      cmd << " -u '#{tpp_url}'" if tpp_url
      cmd << " -z '#{zone}'" if zone
      cmd << " -cert-file '#{cert_path}'" if cert_path
      cmd << " -key-file '#{key_path}'" if key_path
      cmd << " -chain-file '#{chain_path}'" if chain_path
      cmd << " -pickup-id-file '#{id_path}'" if id_path
      cmd << " -cn '#{common_name}'" if common_name
      cmd << " -instance '#{instance}' -replace-instance -app-info '#{app_info}' -tls-address '#{tls_address}'" if instance && app_info && tls_address
      cmd
    end

    def renew(apikey:, zone:, cert_path:, key_path:, chain_path:, common_name:, id_path:, tpp_username:, tpp_password:, token:, tpp_url:)
      cmd = "#{venafi_install_path} renew -no-prompt"
      cmd << " -k '#{apikey}'" if apikey
      cmd << " -tpp-user '#{tpp_username}' -tpp-password '#{tpp_password}'" if !token
      cmd << " -t '#{token}'" if token
      cmd << " -u '#{tpp_url}'" if tpp_url
      cmd << " -z '#{zone}'" if zone
      cmd << " -cert-file '#{cert_path}'" if cert_path
      cmd << " -key-file '#{key_path}'" if key_path
      cmd << " -chain-file '#{chain_path}'" if chain_path
      cmd << " -id file:#{id_path}" if id_path
      cmd
    end

    def should_renew?(cert_path:, renew_threshold:)
      return false unless renew_threshold
      valid_to = shell_out("cut -d \"=\" -f2 <<< $(openssl x509 -enddate -noout -in #{cert_path})").stdout
      valid_to_epoch = shell_out("date -d \"#{valid_to}\" +\"%s\"").stdout
      curr_date = shell_out('date "+%s"').stdout
      (renew_threshold * 86400 + curr_date.to_i) > valid_to_epoch.to_i
    end
  end
end

Chef::Resource.send(:include, VenafiCookbook::Helper)
Chef::Recipe.send(:include, VenafiCookbook::Helper)
