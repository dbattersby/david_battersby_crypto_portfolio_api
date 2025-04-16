module CacheHelper
  def stub_cache_for(key, value)
    allow(Rails.cache).to receive(:read).with(key).and_return(value)
  end
  
  def expect_cache_write(key, value, expires_in: nil)
    if expires_in
      expect(Rails.cache).to receive(:write).with(key, value, expires_in: expires_in)
    else
      expect(Rails.cache).to receive(:write).with(key, value, any_args)
    end
  end
end

RSpec.configure do |config|
  config.include CacheHelper
end 