require 'multi_json'
require_relative '../util/object_numerism'

class ObservationValidator
  def self.validate(profile, file_path)
    begin
      json = File.open(file_path).read
      data_hash = extract_symmetry_groups(MultiJson.load(json))
      if matches_profile?(profile, data_hash) && payoffs_are_valid?(data_hash)
        filter_content(data_hash)
      end
    rescue Exception => e
      puts e.message
    end
  end

  private

  def self.extract_symmetry_groups(data)
    symmetry_groups = {}
    data["players"].each do |player|
      symmetry_groups[player["role"]] ||= {}
      symmetry_groups[player["role"]][player["strategy"]] ||= []
      symmetry_groups[player["role"]][player["strategy"]] <<
        { "payoff" => player["payoff"], "features" => player["features"] }
    end
    new_symmetry_groups = []
    symmetry_groups.each do |role, shash|
      shash.each do |strategy, players|
        new_symmetry_groups << { "role" => role, "strategy" => strategy,
                                 "players" => players }
      end
    end
    { "features" => data["features"], "symmetry_groups" => new_symmetry_groups }
  end

  def self.filter_content(data)
    data["symmetry_groups"].each do |sgroup|
      sgroup["players"].each do |player|
        player["payoff"] = Float(player["payoff"])
      end
    end
    data
  end

  def self.payoffs_are_valid?(data)
    data["symmetry_groups"].detect do |symmetry_group|
      symmetry_group["players"].detect do |player|
        payoff_invalid?(player)
      end
    end == nil
  end

  def self.payoff_invalid?(player)
    !player['payoff'].numeric?
  end

  def self.matches_profile?(profile, data)
    data = data["symmetry_groups"].map{ |sgroup| signature_of_hash(sgroup) }
    pdata = profile.symmetry_groups.map do |sgroup|
      signature_of_symmetry_group(sgroup)
    end
    data = data.sort{ |x,y| x[:role]+x[:strategy] <=> y[:role]+y[:strategy] }
    pdata = pdata.sort{ |x,y| x[:role]+x[:strategy] <=> y[:role]+y[:strategy] }
    data == pdata
  end

  def self.signature_of_hash(symmetry_group)
    { role: symmetry_group["role"],
      strategy: symmetry_group["strategy"],
      count: symmetry_group["players"].size }
  end

  def self.signature_of_symmetry_group(symmetry_group)
    { role: symmetry_group.role,
      strategy: symmetry_group.strategy,
      count: symmetry_group.count }
  end
end