module ApplicationHelper
  def server_version
    @server_version ||= File.read("#{Rails.root}/VERSION").lines.first.chomp
  end
end
