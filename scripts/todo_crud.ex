defmodule TodoList do

	defstruct auto_id: 1, entries: HashDict.new

	# what is the \\ doing? 
	# \\ defines the default value to use in place of entries, if no value is provided
	def new(entries \\ []) do
		Enum.reduce(
			entries,
			%TodoList{},
			fn(entry, todo_list_acc) -> 
				add_entry(todo_list_acc, entry)
			end
		)
		# shorthand for lambda is to use capture: &add_entry(&2, &1)
		# why does &2 correspond to the list and &1 to the item to add? 
		# because the lambda is invoked that way by Enum.reduce/3
	end
	 	
#	def new, do: %TodoList{}

	def add_entry(
		%TodoList{entries: entries, auto_id: auto_id} = todo_list,
		entry
		) do

		entry = Map.put(entry, :id, auto_id)
		new_entries = HashDict.put(entries, auto_id, entry)

		#IO.puts(todo_list)
		#IO.puts(new_entries)
		#IO.puts(auto_id)

		%TodoList{todo_list | entries: new_entries, auto_id: auto_id + 1}
			
	end	

	def update_entry(todo_list, %{} = new_entry) do
		update_entry(todo_list, new_entry.id, fn() -> new_entry end)
	end

	# ln: 25 match entries hashdict
	def update_entry(
		%TodoList{entries: entries} = todo_list,
		entry_id,
		updater_fun
		) do
		# entries: hashdict with the list of todolist entries
		# todo_list: original todo_list item
		# entry_id: the id value of the one you want to modify
		# updater_fun: lambda for how to update the entry we want to update

		#this little guy uses the entry_id value to get the number! duh!
		case entries[entry_id] do
			nil -> todo_list

			old_entry -> 
				old_entry_id = old_entry.id
				#new_entry = updater_fun.(old_entry) #<- asserts nothing...can cause errors
				#new_entry = %{} = updater_fun.(old_entry) #<- asserts that the lambda returns a map
				new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry) # assert that the updated map has the same id value
				new_entries = HashDict.put(entries, new_entry.id, new_entry)
				%TodoList{todo_list | entries: new_entries}
		end

		
	end

	def delete_entry(
		%TodoList{entries: entries} = todo_list,
		entry_id
		) do
		%TodoList{todo_list | entries: HashDict.delete_entry(entries, entry_id)}

	end

	def entries(%TodoList{entries: entries}, date) do
		entries
		|> Stream.filter(fn({_, entry}) -> 
			#IO.puts(entry.date)
			#IO.puts(date)
			entry.date == date
			end)
		|> Enum.map(fn({_, entry}) -> 
			entry
			end)
		
	end
		
end

defmodule TodoList.CsvImporter do
	
	def import(filename) do
		filename
		|> read_lines
		|> create_entries
		|> TodoList.new


#		File.stream!(filename)
#		|> Stream.map(&String.replace(&1, "\n", ""))
#		|> Stream.map(fn(item) -> 
#			String.split(item,",")
#			end)
#		|> convert_date
#		|> Enum.to_list
#		|> List.to_tuple
#		|> IO.inspect
		
	end

	defp read_lines(filename) do
		filename
		|> File.stream! # stream! breaks the file into lines anyway
		|> Stream.map(&String.replace(&1, "\n", "")) # remove end of line character

	end

	defp create_entries(lines) do
		lines
		|> Stream.map(&extract_fields/1)
		|> Stream.map(&create_entry/1)
	end

	defp extract_fields(line) do
		line
		|> String.split(",") # split each line into a list pass it into convert date
		|> convert_date
	end

	defp convert_date([date_string, title]) do
		{parse_date(date_string), title} # use pattern matched list into tuple
	end

	defp parse_date(date_string) do
		date_string
		|> String.split("/") # split date by / chars
		|> Enum.map(&String.to_integer(&1)) # convert each str element into integer
		|> List.to_tuple # take list of ints and convert to tuple
	end

	defp create_entry({date, title}) do
		%{date: date, title: title} # tuple to map
	end

end