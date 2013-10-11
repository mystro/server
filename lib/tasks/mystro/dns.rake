namespace :mystro do
  namespace :dns do
    task :zones => :environment do
      a = Mystro::Organization.get('material')
      d = a.dns
      ap d

      f = d.fog
      ap f

      d.zones.each do |z|
          puts "  #{z.id} #{z.domain}"
      end
    end
  end
end
