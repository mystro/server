module ApplicationHelper
  def server_version
    @server_version ||= File.read("#{Rails.root}/VERSION").lines.first.chomp
  end

  def current_account_name
    @current_account_name ||= current_user.account
  end

  def current_account
    @current_account ||= Account.named(current_user.account)
  end

  def widget_data(o)
    case o.class
      when Compute then widget_data_compute(o)
      when Environment then widget_data_environment(o)
      else
        raise "unknown widget type: #{o.class}"
    end
  end

  def widget_data_compute(compute)
    rows = [{color: :blue, key: :roles, value: compute.roles_string}]
    rows << {color: :green, key: :balancer, value: compute.balancer.name} if compute.balancer
    {
        title: "#{compute.name}#{compute.num}",
        timer: distance_of_time_in_words_to_now(compute.synced_at),
        view: compute_path(compute),
        edit: edit_compute_path(compute),
        destroy: compute_path(compute),
        warning: compute.old?,
        error: compute.deleting,
        rows: rows,
        blocks: [],
    }
  end
  def widget_data_environment(e)
    rows = []
    pc = e.protected ? :green : :red
    tc = e.template && e.template.name != "empty" ? :green : :red
    rows << {color: pc, key: :protected, value: e.protected}
    rows << {color: tc, key: :template, value: e.template.name} if e.template
    e.versions.each do |version|
      (p, b, v) = version.to_s.split(/[\@\:]/)
      rows << {color: :blue, key: p, value: "#{b} (#{v})", link: "/plugins/volley/#{p}/#{b}/#{v}"}
    end
    blocks = []
    blocks << {color: :green, key: :computes, value: e.computes.count}
    blocks << {color: :blue, key: :balancers, value: e.balancers.count}
    blocks << {color: :green, key: :records, value: e.records_count}
    {
        title: e.name,
        timer: distance_of_time_in_words(e.age),
        star: "/home/widget/#{e.name}",
        view: environment_path(e),
        edit: edit_environment_path(e),
        destroy: environment_path(e),
        warning: e.old?,
        error: e.deleting,
        rows: rows,
        blocks: blocks,
    }
  end
end
