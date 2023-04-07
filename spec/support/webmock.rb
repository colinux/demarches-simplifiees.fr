require 'webmock/rspec'

driver_urls = Webdrivers::Common.subclasses.map(&:base_url)
driver_urls << /geckodriver/
driver_urls << "https://objects.githubusercontent.com"

# # We've seen [a redirect](https://github.com/titusfortner/webdrivers/issues/204) to this domain
# driver_urls [/geckodriver/] # this is added

WebMock.disable_net_connect!(allow_localhost: true, net_http_connect_on_start: true, allow: driver_urls)
