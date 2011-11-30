#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'active_support/all'

DataMapper.setup(:default, ENV['DATABASE_URL'])

class Dose
  include DataMapper::Resource
  property :id,       Serial
  property :taken_at, DateTime
  property :pill,     Text
  property :mg,       Integer
end

DataMapper.auto_upgrade!

PILLS = {
  'tylenol' => {
    :every =>  4,
    :mg => 1500
  },
  'advil' => {
    :every => 4,
    :mg => 600
  },
  'oxycodone' => {
    :every => 6,
    :mg => 5
  }
}

class App < Sinatra::Application

  use Rack::Auth::Basic, "Painkiller Jane" do |username, password|
    [username, password] == [ENV['PKJ_USER'], ENV['PKJ_PASS']]
  end

  before do
    @pills = PILLS
    Time.zone = 'America/Los_Angeles'
  end

  get '/' do
    @doses = Dose.all(:order => [:taken_at.desc ])
    latest_doses = repository(:default).adapter.select('select pill, taken_at from doses where (pill, taken_at) in (select pill, max(taken_at) from doses group by pill)')
    @latest_doses = latest_doses.inject({}) do |state,dose|
      state[dose.pill] = dose.taken_at
      state
    end
    erb :index
  end

  post '/' do
    pill = params['pill']
    details = PILLS[pill]
    @dose = Dose.create(
      :pill     => pill,
      :mg       => details[:mg],
      :taken_at => Time.now.utc
    )
    redirect '/'
  end

end