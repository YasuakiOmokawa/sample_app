class Gaproject < ActiveRecord::Base
  def encryptor
    secure = Secret.find(1).secret
    ::ActiveSupport::MessageEncryptor.new(secure, cipher: 'aes-256-cbc')
  end

  def proj_owner_email=(val)
    encryptor = self.encryptor
    write_attribute("proj_owner_email",encryptor.encrypt_and_sign(val))
  end

  def proj_owner_email
    encryptor = self.encryptor
    encryptor.decrypt_and_verify(read_attribute("proj_owner_email"))
  end

  def proj_owner_password=(val)
    encryptor = self.encryptor
    write_attribute("proj_owner_password",encryptor.encrypt_and_sign(val))
  end

  def proj_owner_password
    encryptor = self.encryptor
    encryptor.decrypt_and_verify(read_attribute("proj_owner_password"))
  end
end
