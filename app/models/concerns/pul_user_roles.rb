module PulUserRoles
  extend ActiveSupport::Concern

  def image_editor?
    roles.where(name: 'image_editor').exists?
  end

  def editor?
    roles.where(name: 'editor').exists?
  end

  def fulfiller?
    roles.where(name: 'fulfiller').exists?
  end

  def curator?
    roles.where(name: 'curator').exists?
  end

  def campus_patron?
    persisted? && provider == "cas"
  end

  def anonymous?
    !persisted?
  end
end
