# Venafi Helper Cookbook

### Description

This is a venafi cookbook which will connect with an existing TPP (Trust Protection Platform) Venafi Server or Venafi Cloud, and enroll and manage your certs. 

In order to use the venafi-helper you need to utilize the custom resource and call it from your recipes. 

### venafihelper Properties

- `common_name`: The common name of your certificate (e.g. "bla.example.com")
  - name property
- `tpp_url`: The URL you use to authenticate with the SDK
- `tpp_username`: The username you use to authenticate with the SDK
- `tpp_password`: The password you use to authenticate with the SDK
- `zone`: The zone of your certificate (e.g. "Certificates\\\\Bla")
- `location`: Where you want to write the certificates to disk
- `device_name`: Name of Device you want to create in Venafi Server
  - default: node FQDN
- `app_name`:
- `apikey`: API used to communicate with Venafi Cloud
- `id_path`:
- `app_info`:
- `tls_address`:
- `renew_threshold`:

For examples please see the test fixtures in the `test/` directory.
