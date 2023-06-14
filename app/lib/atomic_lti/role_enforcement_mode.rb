module AtomicLti
  module RoleEnforcementMode
    # Unkown roles are allowed to be the only role in the roles claim
    DEFAULT = "DEFAULT".freeze
    # Unkown roles are not allowed to be the only roles in the roles claim
    STRICT = "STRICT".freeze
  end
end
