module MagicFieldExtension


  def items=(default)
    if default.present?
      write_attribute(:items, default.split(','))
    end
  end


end