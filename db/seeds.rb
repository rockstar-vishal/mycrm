Role.find_or_create_by(name: "System Administrator", active: true)
Role.find_or_create_by(name: "Super Administrator", active: true)
Role.find_or_create_by(name: "Manager", active: true)
Role.find_or_create_by(name: "Executive", active: true)
Role.find_or_create_by(name: "Secondary Level Admin", active: true)
Role.find_or_create_by(name: "Telemarketer", active: true)
Role.find_or_create_by(name: "Supervisor", active: true)
## Enquiry sources
Source.find_or_create_by(name: "Website", active: true)
Source.find_or_create_by(name: "Incoming Call", active: true)
Source.find_or_create_by(name: "99Acres", active: true)
Source.find_or_create_by(name: "Magicbricks", active: true)
Source.find_or_create_by(name: "Walkin", active: true)
Source.find_or_create_by(name: "Client Referral", active: true)
Source.find_or_create_by(name: "Management Referral", active: true)
Source.find_or_create_by(name: "SMS", active: true)
Source.find_or_create_by(name: "Mailer", active: true)
Source.find_or_create_by(name: "Hoarding", active: true)
Source.find_or_create_by(name: "Others", active: true)
Source.find_or_create_by(name: "Broker", active: true)
Source.find_or_create_by(name: "Mcube", active: true)

City.find_or_create_by(name: "Navi Mumbai")
City.find_or_create_by(name: "Mumbai")
City.find_or_create_by(name: "Thane")

## Statuses
Status.find_or_create_by(name: "New", class_name: "Lead")
Status.find_or_create_by(name: "Attempted to Contact", class_name: "Lead")
Status.find_or_create_by(name: "Following", class_name: "Lead")
Status.find_or_create_by(name: "Call Back Today", class_name: "Lead")
Status.find_or_create_by(name: "Warm", class_name: "Lead")
Status.find_or_create_by(name: "Hot", class_name: "Lead")
Status.find_or_create_by(name: "Very Hot", class_name: "Lead")
Status.find_or_create_by(name: "Site Visit Planned", class_name: "Lead")
Status.find_or_create_by(name: "Booking Done", class_name: "Lead")
Status.find_or_create_by(name: "Broker", class_name: "Lead")
Status.find_or_create_by(name: "Cheque Picked", class_name: "Lead")
Status.find_or_create_by(name: "Dead", class_name: "Lead")

stages = [
  'Wrong No',
  'Already Purchased',
  'Site Visit Planned',
  'Low Budget',
  'Meeting Again',
  'Drop the plan',
  'Property planned postponed',
  'FN Planned',
  'Discount Issue',
  'Payment Flexibility',
  'Inventory Issue',
  'Need time to think',
  'Ringing',
  'Switch Off',
  'Not Reachable'

]
stages.each do |stage|
  Stage.find_or_create_by(name: stage)
end