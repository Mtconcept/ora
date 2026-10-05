# Ora has no business-registry, places, facility-registry or bank-verification integration yet.
# Each lookup names the source it would call and reports that it is unavailable, so onboarding falls
# back to recording what operations confirmed by hand, with the evidence that supports it. Wiring a
# real provider means returning a populated Result here; no screen above this needs to change.
module Lookup
  Result = Struct.new(:available, :record, :source, :note, keyword_init: true) do
    def available? = available
  end

  def self.organisation(_registration_number) = unavailable("CAC business register", "Record the organisation exactly as it appears on the CAC certificate on file.")
  def self.place(_query) = unavailable("Places and maps provider", "Enter the address from the provider's own confirmation.")
  def self.facility(_registration) = unavailable("Healthcare facility register", "Verify the facility licence directly with the regulator, then record what you saw.")
  def self.bank_account(_number, _bank) = unavailable("Bank account verification", "Confirm the account name on a bank statement or letter from the provider.")

  def self.unavailable(source, note) = Result.new(available: false, record: nil, source: source, note: note)
end
