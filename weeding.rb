# This script makes a few assumptions, based on the CSV methods in the standard library of Ruby:

# 1. Your file has headers, and they are the very first row of your data. Column names are derived from your headers, so if you need to make them more descriptive, do that.
# 2. You know at least part of the name(s) of the collections or call numbers that you want to weed with, and those collection names are in your file somewhere, because there's some regex matching going on.
# 3. When weeding by date, you want to weed things older than the date you input as your comparison date. 
# 4. If selecting multiple columns or headers for data, the data in all of those columns is in the same format, so that we can compare apples to apples.

# If you want to work on making these assumptions explicit asks, go for it!

require 'csv'
require 'date'

class WeedingHelper

	def initialize()
		# Let's get a file! Type in the name or path to the file here.
		begin
			puts "Type the name of or path to the file to use, including the extension."
			print "> "
		
			file_path = gets.chomp

		# And now, we ask what the column separator is, just in case someone gets a file with semicolons or tabs instead.

			puts "What separates each cell of data in your file? (e.g. , ; ) Use a \\t for a tab."
			print "> "

			separator_symbol = gets.chomp
		
			# We're going to slurp it all in and then convert it to an array of arrays, with the header data as the first item in the array itself. Then, the headers themselves are getting shuttled off to a new variable so that they can be used in a few different methods later on. We're also creating a new array to hold all of the possible weeds.
			print "Reading your file..." 
			@file_data = CSV.read(file_path, headers: true, col_sep: separator_symbol).to_a.compact
			@headers = @file_data[0]
			print "done! \n"
		rescue
			puts "Your path didn't work, or that file doesn't exist!"
			retry
		end
		
		
	end

	def collection_selection()
		
		# Selecting which column holds the information about which collection to use by calling choose_column

		puts "Which column has collection names in it?"
		choose_column()
		
		puts "Which collection do you want to use? (Type EXIT to exit)"
		print "> "
		
		# Notice we're using a regular expression here. This lets you put in something like "YA" or "J" and collect all of the collections that have that in their name. Of course, that means there may be some unexpected hilarity depending on what you put in. For example, collecting plaYAways when you wanted YA materieals.
		collection = gets.chomp
		case collection
			when "exit", "EXIT"
				puts "Exiting the program..."
			else
				@chosen_indexes.each do |idx|
					@file_data.keep_if { |row| row[idx] != nil }
					@file_data.keep_if { |row| row[idx].match /#{collection}/}
				end
				# Moving on to the next part, then...
				criteria_selection()
			end
	end
	
	def criteria_selection()
		# This could be expanded based on other selection criteria.
		# "Both" assumes you want to weed out by date first, then by circulation, because a lot of newer stuff is going to have less circulation and will pollute your results.
		begin
			puts "What would you like to use to build a weeding list?"
			puts "1. Dates / Age"
			puts "2. Circulation"
			puts "3. Both"
			puts "Type the number or the name you would like to use. Type EXIT to exit."
			print "> "
			option_selected = gets.chomp.downcase
			case option_selected
			when "1", "dates", "age"
				# First, do comparison by date
				compare_dates()
				# Then, call the file writer to create a file with what we've requested.
				write_candidates()
			when "2", "circulation"
				# First, compare by circulations...
				compare_circs()
				# Then, call the file writer to create a file with the information we've requested.
				write_candidates()
			when "3", "both"
				# Compare first by date, then by circ, 
				compare_dates()
				compare_circs()
				# Then, call the file writer to create a file with the information we've requested.
				write_candidates()
			when "exit"
				puts "Exiting the program."
			else
				raise ArgumentError, "Unknown command number or word"
			end
		rescue ArgumentError
			puts "I don't understand that."
			retry
		end
	end

	def choose_column()
		# First, let's iterate over the headers. 
		# each_with_index is an awesome method when you want a numbered list - just remember humans count from 1 and machines count from 0.
		# Oh, and that you can't concatenate integers with strings, so we have to do to_s on the index.
		begin
			puts ""
			@headers.each_with_index do |header, index|
				if header != nil
					puts (index + 1).to_s + " " + header
				else
					print ""
				end
			end
		
			# Because it's possible you would want to do comparisons based on multiple columns...
			puts ""
			puts "Separate multiple columns with commas"
			puts ""
			print "> "
			# Split the input string and put each element into an array...
			@chosen_indexes = gets.chomp.split(",").map(&:to_i)
			# ...then destructively replace them with the correct index value, because machines still count from 0.
			@chosen_indexes.map! { |idx| idx - 1 }
			# ...now check to make sure that the numbers used actually correspond to real columns!
			@chosen_indexes.each do |idx|
				unless idx.between?(0,@headers.length - 1)
					raise ArgumentError, "Invalid column number"
				end
			end
			rescue ArgumentError
			puts "One of your numbers isn't a real column."
			retry
		end
		
		

	end

	def compare_dates()
		# First, choose which column actually has the information we're looking for...
		puts "Which column(s) have the dates you want to use?"
		choose_column()
		
		# Then, pull in the date formatter, so we know how the data is formatted.
		date_formatter()
		
		begin
			puts "Keep items before what date?"
			puts "Please use yyyy-mm-dd formatting."
			print "> "
			comparison_date = gets.chomp
			comparing_date = Date.strptime(comparison_date, "%Y-%m-%d")
		rescue ArgumentError
			puts "That's not a date I can work with!"
			retry
		end
		# And finally, the actual magic itself: 
		# If the date in the column is earlier than the comparison date, keep the record as a weeding candidate.

		candidates_array = Array.new
		@file_data.each do |row|
			@chosen_indexes.each do |idx|
				if Date.strptime("#{row[idx]}", "#{@date_formatting}") < comparing_date
					candidates_array.push(row)
				end
			end
		end
		# Because something could be a candidate in more than one column, we need to get rid of the duplicates with uniq, and then overwrite the previous array with the new one.
		@file_data = candidates_array.uniq
	
	end

	def compare_circs()
		# First, choose which column actually has the information we're looking for.
		puts "Which column(s) have the circulation information you want to use?"
		choose_column()
		
		# Next, tell us how to interpret what we find - as an absolute or as an average per year.
		begin
			puts "How do you want to compare this data?"
			puts "1. Absolute - if circulation is less than or equal to the minimum number of circulations, it is a weed candidate."
			puts "2. Average - if circulation per year is less than or equal to the minimum number of circulations per year, it is a weed candidate."
			puts "Please enter the number, absolute, or average."
			print "> "
			compare_choice = gets.chomp.downcase
			case compare_choice
				when "1", "absolute"
					# Ask what the minimum is, then iterate over each row, comparing what's in the column to the minimum. Less than or equal are candidates, greater than isn't.
					puts "How many circulations, at minimum, does the item need to avoid weeding?"
					print "> "
					minimum_circs = gets.chomp.to_i
					candidates_array = Array.new
						@file_data.each do |row|
						@chosen_indexes.each do |idx|
							if (row[idx]).to_i <= minimum_circs
								candidates_array.push(row)
							end
						end
					end
					# Because something could be a candidate in more than one column, we need to get rid of the duplicates with uniq, and then overwrite the previous array with the new one.
					@file_data = candidates_array.uniq
				
				when "2", "average"
					# Ask first what the minimum circulations per year is.
					puts "How many circulations per year does the item need to avoid weeding?"
					print "> "
					minimum_circs = gets.chomp.to_i
				
					# Then figure out what date to use so that we can make comparisons.
					# But first, store the columns we chose earlier into another variable so they aren't overwritten.
					puts "Which column has the date the item first appeared?"
					circ_columns = @chosen_indexes
					choose_column()
					date_formatter()
					candidates_array = Array.new
					@file_data.each do |row|
						circ_columns.each do |circ|
							@chosen_indexes.each do |idx|
								# Find out how many years an item has been in the collection...
								years_here = (Date.today.year.to_s.to_i) - (Date.strptime("#{row[idx]}", "#{@date_formatting}").year.to_s.to_i)
								# Then do the averaging math - circulations divided by years...
								average_circs_per_year = row[circ].to_i / years_here.to_i
								# ...and if the average is too low, put it in as a weeding candidate.
								if average_circs_per_year <= minimum_circs
									candidates_array.push(row)
								end
							end
						end
					end
				# Because something could be a candidate in more than one column, we need to get rid of the duplicates with uniq, and then overwrite the previous array with the new one.
				@file_data = candidates_array.uniq
			else
				puts "Right, that's not something I get. Exiting."
				raise ArgumentError, "Invalid Choice, yo."
			end
		rescue
			puts "I didn't understand that."
			retry
		end
	end
		
		 	
	def date_formatter()
		# TODO: Maybe push this entire sequence into a separate file and have it write out a config thing that we can pull in, so that way nobody has to go through answering all these questions all the time?

		# Figure out how the dates are formatted, so that we can pass useful info to Date.strptime without forcing someone to know how to use strptime formatting.
		begin
			puts "In your file, is January represented as:"
			puts "1. A number (i.e. 01 or 1)"
			puts "2. Jan"
			puts "3. January"
			puts "Enter the number of the option" 
			print "> "

			month_type = gets.chomp.downcase
			case month_type
				when "1", "number"
					month_type = "%m"
				when "2", "Jan"
					month_type = "%b"
				when "3", "January"
					month_type = "%B"
				else
					raise ArgumentError, "Bad Month"
				end
		
			puts "In your file, is the first day of a month represented as:"
			puts "1. 01"
			puts "2. 1"
			puts "Enter the number of the option"
			print "> "
			day_type = gets.chomp
			case day_type
				when "1", "01"
					day_type = "%d"
				when "2"
					day_type = "%d"
				else
					raise ArgumentError, "Bad Day"
				end
		
			puts "In your file, are years represented with:"
			puts "1. 2 digits (e.g. 99, 15)"
			puts "2. 4 digits (e.g. 2015, 1980)"
			print "> "
			year_type = gets.chomp.downcase
			case year_type
				when "1", "2 digits"
					year_type = "%y"
				when "2", "4 digits"
					year_type = "%Y"
				else
					raise ArgumentError, "Bad Year"
				end
			
			puts "In your file, what character separates the day, month, and year?"
			puts "e.g. / or -"
			print "> "
			separator_character = gets.chomp
		
			puts "In your file, how are your dates ordered?"
			puts "1. Year-Month-Day"
			puts "2. Year-Day-Month"
			puts "3. Month-Day-Year"
			puts "4. Day-Month-Year"
			print "> "
			date_formatting = gets.chomp.downcase
			case date_formatting
				when "1", "year-month-day"
					@date_formatting = year_type + separator_character + month_type + separator_character + day_type
				when "2", "year-day-month"
					@date_formatting = year_type + separator_character + day_type + separator_character + month_type
				when "3", "month-day-year"
					@date_formatting = month_type + separator_character + day_type + separator_character + year_type
				when "4", "day-month-year"
					@date_formatting = day_type + separator_character + month_type + separator_character + year_type
				else
					raise ArgumentError, "Bad Ordering"
				end
		rescue ArgumentError
			puts "Invalid Value. Restarting..."
			retry
		end
	end

	def write_candidates()
		begin
			puts "What name would you like your file to have?"
			file_path = gets.chomp
			print "Writing your weeding candidates..."
			CSV.open(file_path, "wb") do |csv|

				@file_data.each do |row|
					csv << row
				end
			end
			print "done!"
			puts ""
			puts "Open #{file_path} to see what you've created."
		rescue
			puts "That path doesn't exist, or you have the file open in some other program. Make sure everything is closed before trying again."
			retry
		end
	end
end

helper = WeedingHelper.new
helper.collection_selection
