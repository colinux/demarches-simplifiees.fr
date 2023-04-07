VCR.configure do |c|
  c.ignore_localhost = true
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.configure_rspec_metadata!

  # ignore selenium driver hosts. From https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock
  driver_hosts = Webdrivers::Common.subclasses.map { |driver| URI(driver.base_url).host }
  driver_hosts << "objects.githubusercontent.com" # redirected here to download drivers
  c.ignore_hosts 'test.host', *driver_hosts
end
