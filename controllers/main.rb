class Main < Sinatra::Base
  set :views,File.dirname(__FILE__) + '/../views'

  helpers WillPaginate::Sinatra::Helpers  
  helpers do
    def paginate(collection)
      options = {
        inner_window: 0,
        outer_window: 0,
        previous_label: '&laquo;',
        next_label: '&raquo;'
      }
      will_paginate collection, options
    end
  end

  get '/' do
    sql,sql_hash = " 1=1 ",{}
    unless params[:keywords].nil?
      sql += " and (serial_pics.title like :keywords or exists( select 1 from pic_tags inner join pic_tags_serial_pics where pic_tags_serial_pics.serial_pic_id = serial_pics.id and pic_tags_serial_pics.pic_tag_id = pic_tags.id and pic_tags.name like :keywords) or serial_pics.mm_name like :keywords )"
      sql_hash.merge! keywords:"%#{params[:keywords]}%"
    end
    @serials =  SerialPic.where(sql,sql_hash).order("serial_pics.id desc").paginate(per_page:30,page:params[:page])
    @pic_count = Picture.count
    @done_count = Picture.where(status:true).count
    haml :index,locals:{serials:@serials,pic_count:@pic_count,done_count:@done_count,keywords:params[:keywords]}
  end

  get '/pics/:id' do
    serial = SerialPic.includes([:pictures,:pic_tags]).find_by_id(params["id"])
    haml :pics,locals:{serial:serial}
  end

end
