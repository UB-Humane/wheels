require "test_helper"

class DonorTest < ActiveSupport::TestCase
  def build_donor(attrs = {})
    Donor.new({ first_name: "Jane", last_name: "Doe", production: productions(:main_production) }.merge(attrs))
  end

  test "valid with first and last name only" do
    assert build_donor.valid?
  end

  test "requires first name" do
    donor = build_donor(first_name: "")
    assert_not donor.valid?
    assert_includes donor.errors[:first_name], "can't be blank"
  end

  test "requires last name" do
    donor = build_donor(last_name: "")
    assert_not donor.valid?
    assert_includes donor.errors[:last_name], "can't be blank"
  end

  test "email is optional" do
    assert build_donor(email: nil).valid?
  end

  test "mobile is optional" do
    assert build_donor(mobile: nil).valid?
  end

  test "address is optional" do
    assert build_donor(address: nil).valid?
  end

  test "full_name returns first and last name" do
    assert_equal "Jane Doe", build_donor.full_name
  end

  test "default archived is false" do
    donor = build_donor.tap(&:save!)
    assert_not donor.archived?
  end

  test "active scope excludes archived donors" do
    assert_includes Donor.active, donors(:active_donor)
    assert_not_includes Donor.active, donors(:archived_donor)
  end

  test "archived scope excludes active donors" do
    assert_includes Donor.archived, donors(:archived_donor)
    assert_not_includes Donor.archived, donors(:active_donor)
  end
end
