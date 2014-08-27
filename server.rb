require 'csv'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'pg'

def db_connection
  begin
    connection = PG.connect(dbname: 'slacker_news')

    yield(connection)

  ensure
    connection.close
  end
end

def get_data(query)
  db_connection do |conn|
    conn.exec(query)
  end
end

def already_submitted post_url

  check_url = 'SELECT url FROM articles
                WHERE url = $1'

  duplicate = db_connection do |conn|
    conn.exec_params(check_url, [post_url])
  end

  if duplicate.to_a.size == 0
    return false
  end
  true
end

def post_is_valid?(post_title, post_url, post_description)

  if !title_is_valid? post_title
    return false

  elsif !url_is_valid? post_url
    return false

  elsif !description_is_valid? post_description
    return false
  elsif already_submitted post_url
    return false
  end
  true
end

def title_is_valid? post_title
  post_title != ''
end

def url_is_valid? post_url
  if post_url !~ (/^(www)\.\w+\..{2,6}$/)
    return false
  end
  true
end

def description_is_valid? post_description
  if post_description == nil || post_description.length < 20
    return false
  end
  true
end



get '/' do
  query = 'SELECT articles.id, articles.title, articles.url, articles.descriptions,
            comments.id AS comment_id
            FROM articles LEFT OUTER JOIN comments
            ON articles.id = comments.article_id'
  @articles = get_data(query)
  erb :index
end

get '/submit' do
  erb :submit
end

post '/submit' do
  if post_is_valid?(params[:post_title], params[:post_url], params[:post_description])
    @title = params[:post_title]
    @url = params[:post_url]
    @descriptions = params[:post_description]
    input = "INSERT INTO articles(
      title, url, descriptions)
      VALUES ($1, $2, $3)"
    db_connection do |conn|
      conn.exec_params(input, [@title, @url, @descriptions])
    end
  redirect '/'
  else
    @error = 'Invalid input'
    @post_title = params[:post_title]
    @post_url = params[:post_url]
    @post_description = params[:post_description]
    if !title_is_valid? @post_title
      @error = 'Invalid title'
    elsif !url_is_valid? @post_url
      @error = 'Invalid url (FORMAT: www.google.com'
    elsif !description_is_valid? @post_description
      @error = 'Description must be at least 20 characters'
    elsif already_submitted @post_url
      @error = 'This URL has already been posted'
    end
    erb :submit
  end
end

get '/articles/:article_id/comments' do
  query = 'SELECT articles.id, articles.title, articles.url, articles.descriptions,
            comments.id AS comment_id, comments.comment
            FROM articles LEFT OUTER JOIN comments
            ON articles.id = comments.article_id
            WHERE articles.id = $1'

  query_comments = 'SELECT articles.id, comments.username, comments.comment, comments.id AS comment_id
            FROM comments JOIN articles
            ON articles.id = comments.article_id
            WHERE articles.id = $1'
  #binding.pry
  db_connection do |conn|
    @articles = conn.exec_params(query, [params[:article_id]])
    @comments = conn.exec_params(query, [params[:article_id]])
  end
  #binding.pry
  erb :comments
end


post '/articles/:article_id/comments' do
  @user = params[:username]
  @comment = params[:comment]
  @id = params[:article_id]

  #binding.pry
  insert_comment = 'INSERT INTO comments(
                    username, comment, article_id)
                    VALUES ($1, $2, $3)'


  db_connection do |conn|
      conn.exec_params(insert_comment, [@user, @comment, @id])
    end
    #binding.pry
  erb :comments
end
