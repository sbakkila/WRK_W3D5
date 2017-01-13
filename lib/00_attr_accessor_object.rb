class AttrAccessorObject

  def initialize
  end

  def self.my_attr_accessor(*names)

    names.each do |name|
      define_method(name) do
        instance_variable_get("@".concat(name.to_s))
      end
    end

    names.each do |name|
      define_method(name.to_s.concat('=')) do |arg = nil|
        instance_variable_set("@".concat(name.to_s), arg)
      end
    end

  end


end
