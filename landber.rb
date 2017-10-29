require 'uri'
require 'net/http'
require 'net/https'
require 'json'

class Crawler
  @@page = 1
  @@per_page = 30

  @@header = {
    'Host' => 'landber.com',
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0',
    'Accept' => 'application/json',
    'Content-Type' => 'application/json;charset=utf-8',
    'Connection' => 'keep-alive',
    'Cookie' => '_ga=GA1.2.829097572.1506998552; intercom-session-kmayxcxz=clg2anZkRy84L1NLb21WMmw0RC9wdGpDcFQ0a05XQ05JYllwVDE4UkwxL1poRlZRZjIyWmNYeHhGUnZTaEpEWC0tdWxFdmVESzJFNWhhMUI3N3VpenJwZz09--3243f77734e8650935c3282961adb48f5ce42d8b; io=RM-0Gd1rKvPU44kcAHcu; myWebUuid=web_9c35a931-e52b-4204-91ce-940e458f308f; _gid=GA1.2.1012464383.1509198417; _gat=1',
    'Authorization' => 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiJVc2VyXzMxMjkzMiIsImV4cCI6MTUwOTgwMzQ1MSwidXNlcm5hbWUiOiJyMTA4NTU5NUBtdnJodC5uZXQiLCJ1c2VySUQiOiJVc2VyXzMxMjkzMiIsImlhdCI6MTUwOTE5ODY1MX0.6nymfdK7YVUBmDfc56TWcm_EvStMUqw3JK9e8RTXnhg'
  }

  def initialize(min_price, max_price, min_area, max_area)
    @min_price = min_price
    @max_price = max_price
    @min_area = min_area
    @max_area = max_area
  end

  def just_do_it()
    puts 'Page: '+@@page.to_s

    post_data = {
      'loaiTin':0,
      'loaiNhaDat':['2'],
      'giaBETWEEN':[@min_price,@max_price],
      'dienTichBETWEEN':[@min_area,@max_area],
      'pageNo':@@page,
      # 'viewport':{'northeast':{'lat':21.0980337,'lon':105.8257627},'southwest':{'lat':21.0718864,'lon':105.7919024}},
      # 'diaChinh':{'fullName':'Phường Phú Thượng, Quận Tây Hồ, Hà Nội','tinhKhongDau':'HN','huyenKhongDau':'6','xaKhongDau':'9374'},
      'viewport':{'northeast':{'lat':21.385027,'lon':106.0198859},'southwest':{'lat':20.562323,'lon':105.2854659}},
      'diaChinh':{'fullName':'Hà Nội','tinhKhongDau':'HN'},
      'userID':'User_312932',
      'limit':@@per_page,
      'isIncludeCountInResponse':true,'updateLastSearch':true,'hasImage':true
    }

    data = post('https://landber.com/api/v2/find', post_data)
    # contents = File.read('data.txt')
    # data = JSON.parse(contents)

    data['list'].each do |item|
      check_owner(item['adsID'])
    end

    if((@@page * @@per_page) < data['totalCount'])
      @@page += 1
      just_do_it()
    end

  end

  def check_owner(post_id)
    post_detail = get_detail(post_id)
    user_data = post_detail['ads']['dangBoi']
    list_post = get_list_post_by_user(user_data)

    if(list_post['data'].length <= 2)
      puts 'https://landber.com/tin-dang/ban-nha-rieng/ha-noi/'+post_id
      out_file = File.new('posts/'+post_id+'.json', 'w+')
      out_file.write(post_detail.to_json)
      out_file.close
    end
  end

  def get_detail(post_id)
    post_data = {'adsID': "#{post_id}"}
    post('https://landber.com/api/detail', post_data)

    # contents = File.read('data.txt')
    # data = JSON.parse(contents)
  end

  def get_list_post_by_user(user_data)
    user_data['loaiTin'] = 0
    user_data.delete('name')
    post('https://landber.com/api/user/getAdsByUser',user_data)
  end

  def post(url, data)
    uri = URI.parse(url)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path, initheader = @@header)
    req.body = data.to_json

    res = https.request(req)
    # puts "Response #{res.code} #{res.message}: #{res.body}"
    JSON.parse(res.body)
  end

end


# Khoang gia * 1.000.000
@min_price = 1500
@max_price = 2300

# Dien tich m2
@min_area = 38
@max_area = 80

crawler = Crawler.new(@min_price, @max_price, @min_area, @max_area)
crawler.just_do_it()