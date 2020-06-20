# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

#https://davidmles.com/seeding-database-rails/
require 'csv'
# Program.destroy_all
# University.destroy_all

csv_text = File.read(Rails.root.join('lib', 'seeds', 'university_program.csv'))
csv = CSV.parse(csv_text, :headers => true)

csv.each do |row|
	university = row[1].to_s.strip
	program = row[0].to_s.strip
	university_exists = University.find_by(university_name: university)

	unless university_exists
		u = University.new
		u.university_name = university
  	u.university_country = "CA"
  	u.university = true
  	u.save
  	university_exists = u 
  	puts university
	end

	program_exists = Program.where(program_name: program, university_id: university_exists.id).first
	unless program_exists
		pr = Program.new
		pr.program_name = program
		pr.university_id = university_exists.id
		pr.save
		puts program
	end

end
