class Connection
  def initialize(options)
    @flux_proxy = options[:proxy]
  end

  def authenticate(options)
    @flux_proxy.authenticate(options[:uniqname], options[:password])
  rescue
    false
  end

  def authenticated?
    @flux_proxy.authenticated?
  end

  def acquire
    if @flux_proxy.authenticated?
      @flux_proxy
    else
      nil
    end
  end
end
