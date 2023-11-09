user = User.create(name: "Michael Scott", email: "michaelscott@dundermifflin.com", admin: "true", password: "password")
user.avatar.attach(io: URI.open("#{Rails.root}/app/assets/images/office-avatars/michael-scott.png"), filename: "michael-scott.png")
user.save!
user = User.create(name: "Jim Halpert", email: "jimhalpert@dundermifflin.com", admin: "false", password: "password")
user.avatar.attach(io: URI.open("#{Rails.root}/app/assets/images/office-avatars/jim-halpert.png"), filename: "jim-halpert.png")
user.save!
user = User.create(name: "Pam Beesly", email: "pambeesly@dundermifflin.com", admin: "false", password: "password")
user.avatar.attach(io: URI.open("#{Rails.root}/app/assets/images/office-avatars/pam-beesly.png"), filename: "jim-halpert.png")
user.save!
# widget = Widget.create(name: "Wrenches", description: "Michael's wrenches", user_id: 1)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/allen-wrenches.jpg"), filename: "allen-wrenches.jpg")
# widget.save!
# widget = Widget.create(name: "Bolts", description: "Michael's bolts", user_id: 1)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/bolts.jpg"), filename: "bolts.jpg")
# widget.save!
# widget = Widget.create(name: "Brackets", description: "Jim's brackets", user_id: 2)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/brackets.png"), filename: "brackets.png")
# widget.save!
# widget = Widget.create(name: "Nuts", description: "Jim's nuts", user_id: 2)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/nuts.jpg"), filename: "nuts.jpg")
# widget.save!
# widget = Widget.create(name: "Pipes", description: "Jim's pipes", user_id: 2)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/pipes.jpg"), filename: "pipes.jpg")
# widget.save!
# widget = Widget.create(name: "Screws", description: "Pam's screws", user_id: 3)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/screws.jpg"), filename: "screws.jpg")
# widget.save!
# widget = Widget.create(name: "Washers", description: "Pam's washers", user_id: 3)
# widget.image.attach(io: URI.open("#{Rails.root}/app/assets/images/widgets/washers.jpg"), filename: "washers.jpg")
# widget.save!