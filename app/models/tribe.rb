class Tribe < ApplicationRecord
  has_many :troops

  def attitude_toward(other_tribe)
    # Eventually we will have pairwise reputations between tribes which we
    # will use to determine whether they are allies, enemies, or neutral,
    # but for now we will just attack if they are not the same
    return -1 if self != other_tribe
    1
  end

end
