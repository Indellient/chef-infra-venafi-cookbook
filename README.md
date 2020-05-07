# venafi-helper

### Description
This is a venafi cookbook whuck will connect with an existing TPP (Trust Protection Platform) Venafi Server and enroll and manage your certs. 

In order to use the venafi-helper you need to port the custim resource and call it from your default recipe. 

in order to use the venafi-helper, you also need to install the ruby gem `vcert`

### Configuring the venafi-helper
| Configuration     | Description                                                                           |
|-------------------|---------------------------------------------------------------------------------------|
|`tpp_username`     | The username you use to authenticate with the SDK                                     |
|`tpp_password`     | The password you use to authenticate with the SDK                                     |
|`policyname`       | The zone of your certificate (e.g. "Certificates\\\\Bla").                            |
|`commonname`       | The common name of your certificate (e.g. "bla.example.com").                         |
|`location`         | Where you want to write the certificates to disk                                      |
|`devicename`       | Name of Device you want to create in Venafi Server                                    |

In your default recipe you would call the venafi-helper custom resource and set the configuration as such: 

```
venafi-helper 'tpp_url' do
    tpp_username 'tppusername'
    tpp_password 'tpppassword'
    policyname   'Policyname'
    commonname   'commonname'
    location     'location'
    devicename   'devicename'
    action :run
end
```