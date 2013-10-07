class Volume
  include Mongoid::Document
  include Mongoid::Timestamps
  include Qujo::Concerns::Model

  embedded_in :compute

  field :name, type: String
  field :device, type: String
  field :size, type: String
  field :dot, type: Boolean
  field :snapshot, type: String
  field :virtual, type: String

  def to_cloud
    data = {
        name: name,
        device: device,
        size: size,
        dot: dot,
        snapshot: snapshot,
        virtual: virtual,
    }
    Mystro::Cloud::Volume.new(data)
  end

  def from_cloud(obj)
    self.name = obj.name if obj.name
    self.device = obj.device if obj.device
    self.size = obj.size if obj.size
    self.dot = obj.dot if obj.dot
    self.snapshot = obj.snapshot if obj.snapshot
    self.virtual = obj.virtual if obj.virtual
  end
end
