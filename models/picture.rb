class Picture < ActiveRecord::Base
  belongs_to :serial_pic
  BASE_PATH = '/Users/oudong/meitu/'

  class << self
    def download_pics
      pool = Pool.new(20)
      SerialPic.where(download_status:false).find_in_batches(batch_size:100) do |serials|
        serials.each do |serial|
          Dalli.logger.info "start serial:#{serial.title}"
          path = "#{Picture::BASE_PATH}#{serial.title}"
          Dir.mkdir(path) unless File.exists?(path)
          serial.pictures.where(status:false).each do |pic|
            trap :INT do
              Dalli.logger.info 'stop'
              return
            end
            unless File.exists?("#{path}/#{pic.name}")
              pool.run(pic,path) do |_pic,_path|
                Dir.chdir _path
                rs = system("wget #{_pic.url} -T 10")
                _pic.update_attributes status:true,completed_at:Time.now if rs
              end
            else
              pic.update_attributes status:true,completed_at:Time.now
            end
          end
        end
      end
      pool.join
    end
  end

  def after_save
    self.serial_pic.update_attributes download_status: 1,downloaded_at: Time.now if self.serial_pic.pictures.all?{|x| x.status? }
  end
end

class PicTag < ActiveRecord::Base
  has_and_belongs_to_many :serial_pics

  class << self
    def batch_create_tags(tags)
      tags.map do |tag|
        self.find_or_create_by(name:tag)
      end
    end
  end
end

class SerialPic < ActiveRecord::Base
  attr_accessor :doc,:url_store
  has_many :pictures
  has_and_belongs_to_many :pic_tags

  MM_NAME_REG = /(?<=模特姓名：)(.+)/

  class << self
    def create_serial(url_store)
      Picture.connection.transaction do
        set = self.find_or_create_by(url:url_store.url)
        set.url_store = url_store
        set.doc = Spider.open_html(set.url_store.url)
        return if set.doc.nil?
        set.expand_attrs
        set.fetch_pics
        set.url_store.update_attributes status:true
      end
    end
  end
  
  def expand_attrs
    name_p = self.doc.css(".width .c_l p").detect{|x|x.children && x.children.text && /模特姓名/ =~ x.children.text}
    name_l = name_p.nil? ? nil : name_p.css("a")
    if !name_l.nil?
      self.mm_name = name_l.children.text
    else
      self.mm_name = $1 if  !name_p.nil? && SerialPic::MM_NAME_REG =~ name_p.children.text
    end
    self.title = doc.css(".weizhi h1").children.text.fmt_url
    tags = doc.css("#fenxiang .fenxiang_l a.tags").map{|x|x.children.text}
    self.pic_tags << PicTag.batch_create_tags(tags)
    self.save
  end

  def fetch_pics
    visited_urls = []
    _doc = self.doc
    _url = self.url
    while true
      visited_urls << _url
      break if _doc.nil?
      self.get_pics(_doc)
      urls = _doc.css("center #pages a").map{|x| Spider::BASE_URL + x.attributes['href'].value}
      _url = urls.detect{|x| !visited_urls.include?(x)}
      self.update_attributes(status:true,completed_at:Time.now) and break if _url.nil?
      _doc = Spider.open_html(_url)
    end
  end

  def refetch_pics
    self.doc = Spider.open_html(self.url)
    self.fetch_pics
  end

  def get_pics(doc)
    doc.css(".content center img").map{|x|x.attributes["src"].value}.each do |url|
      self.pictures.create url:url,name:url.split('/').last unless Picture.exists?(url:url,serial_pic_id:self.id)
    end
  end
end
