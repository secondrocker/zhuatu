class Spider 
  SET_URL_REG = /\/item\/\d+\.html$/
  SERIAL_URL_REG = /meitulu\.com\/t\/[a-z\-]+\/(\d+\.html)?$|meitulu\.com\/(?!item\/)[a-z\-]+\/(\d+\.html)?$/
  BASE_URL = 'https://www.meitulu.com'
  class << self

    def open_html(url)
      times = 0
      while true
        begin
          times += 1
          res = RestClient::Request.execute(method: :get, url: url,timeout: 10)
          doc =  Nokogiri::HTML(res.body)
          return doc
        rescue
          return nil if times >= 3
        end
      end
    end
    
    def fetch_urls(url)
      UrlQueue.push(url)
      while true
        break unless url = UrlQueue.pop
        url = BASE_URL + url unless url.start_with?('https://')
        doc = self.open_html(url)
        next if doc.nil?
        doc.css("a").each do |x|
          _url =  (x.attributes['href'].value rescue nil)
          next if _url.nil?
          _url = BASE_URL + _url unless _url.start_with?('https://')
          if SET_URL_REG =~ _url
            UrlStore.store(_url,(x.children.text rescue nil))
          elsif SERIAL_URL_REG =~ _url
            UrlQueue.push(_url)
          end
        end
        UrlSeen.see url
      end
    end

  end
end

class UrlQueue < ActiveRecord::Base
  class << self
    
    def pop
      _first = self.first
      if _first.nil?
        nil
      else
        _first.destroy.url
      end
    end
    
    def push(url)
      self.create url: url if !UrlSeen.seen?(url) && !self.exists?(url:url)
    end

  end
end

class UrlSeen < ActiveRecord::Base
  
  class << self
    def seen?(url)
      self.exists? url:url
    end

    def see(url)
      self.create url:url unless self.seen?(url)
    end
  end

end

class UrlStore < ActiveRecord::Base
  class << self
    def stored?(url)
      self.exists? url:url
    end

    def store(url,title=nil)
      self.create url:url unless self.stored?(url)
    end

    def fetch_pics
      self.where(status:false).each{|x| SerialPic.create_serial(x)}
    end
  end
end

class String
  def fmt_url
    self.gsub(/^\s*|\s*$/,'').gsub(/\//,'')
  end
end
