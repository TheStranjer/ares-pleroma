module AresMUSH
  module Pleroma
    def self.request(path: "/", body: {}, method: :post, bearer_token: Global.read_config("pleroma", "admin_bearer"))
      uri = URI.parse("https://#{self.instance}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Pleroma::http_class_from_method(method).new(uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{bearer_token}"

      request.body = body.to_json

      body = http.request(request).body

      begin
        JSON.parse(body)
      rescue
        body
      end
    end
  
    def self.http_class_from_method(method)
      case method
      when :post
        Net::HTTP::Post
      when :get
        Net::HTTP::Get
      end
    end

    def self.instance
      @instance ||= Global.read_config("pleroma", "instance_domain")
    end
  end
end
