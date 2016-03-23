class Lita::Standup

  attr_accessor :id, :name, :repeat, :day_of_week, :time, :questions, :channel

  def initialize(params = {})
    params.each do |k,v|
      send("#{k}=", v)
    end
  end

  def save
    Lita.redis["standup-#{id}"] = to_json
    Lita.redis.sadd "standups", id
    self
  end

  def delete
    Lita.redis.del "standup-#{id}"
    Lita.redis.srem "standups", id
    self
  end

  def run
    Lita.logger.debug "Standup will run: #{self.inspect}"
  end

  def cron_line
    [
      parsed_time.min,
      parsed_time.hour,
      "*",
      "*",
      (weekly? ? day_of_week_index : "*")
    ].join(" ")
  end

  def parsed_time
    @parsed_time ||= Time.parse(time)
  end

  def day_of_week_index
    %w(sunday monday tuesday wednesday thursday friday saturday).index(day_of_week)
  end

  def to_json(_ = nil)
    MultiJson.dump(as_json)
  end

  def as_json
    data = {}
    [:id, :name, :repeat, :day_of_week, :time, :questions, :channel].each do |k|
      data[k] = send(k)
    end
    data
  end

  def summary
    day_text = weekly? ? " on #{day_of_week}" : ""
    "#{name} (ID: #{id}) - running #{repeat}#{day_text} at #{time}"
  end

  def description
    [
      "ID: #{id}",
      "Name: #{name}",
      "Running #{repeat} " + (weekly? ? "on #{day_of_week} " : "") + "at #{time}",
      "Questions:",
      questions,
      "Sending the result on #{channel}"
    ].join("\n")
  end

  def weekly?
    repeat == "weekly"
  end

  class << self

    def create(params)
      new(params).save
    end

    def find(id)
      data = Lita.redis["standup-#{id}"]
      data = MultiJson.load(data)
      new(data)
    rescue
      nil
    end

    def all
      Lita.redis.smembers("standups").map do |id|
        find(id)
      end
    end
  end
end
