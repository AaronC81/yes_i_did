def yes
  # This is a proc so that it can return from the "yes" function
  error = proc do |msg|
    puts IRB::Color.colorize("yes: #{msg}", ['RED'])
    return
  end

  # Get the invalid name and the suggestion replacements
  exception = $!

  error.("last command didn't raise an exception") if exception.nil?
  error.("unsupported error type #{exception.class}") unless exception.is_a?(NameError)

  corrections = exception.corrections
  error.("there are multiple possible corrections") if corrections.length > 1
  error.("there are no corrections") if corrections.empty?

  # Get the original, incorrect name as a string
  checker = DidYouMean::NameErrorCheckers.new(exception)
  case checker
  when DidYouMean::ClassNameChecker
    original_name = checker.class_name
  when DidYouMean::VariableNameChecker
    original_name = checker.name
  else
    error.("couldn't find a matching DidYouMean checker - this is a bug!")
  end
  original_name = original_name.to_s

  # Get the last IRB command run
  previous_command = IRB.CurrentContext.io.line(-2)

  # Replace the original with the correction, but only replace a complete
  # identifier
  replacements_made = 0
  fixed_command = previous_command.gsub(/[a-zA-Z_][a-zA-Z_0-9]*[\?!]?/) do |match|
    if match == original_name
      # Replace with correction
      replacements_made += 1
      corrections.first.to_s
    else
      # Keep the same
      match
    end
  end
  error.('couldn\'t make replacements, sorry!') if replacements_made.zero?

  # Print the altered code
  prompt_pad = ' ' * IRB.CurrentContext.io.prompt.length
  output_fixed_command = fixed_command.each_line.map { |line| prompt_pad + line }.join.chomp
  message = IRB::Color.colorize(output_fixed_command, ['GREEN'])
  puts message
  
  # Run it
  eval(fixed_command, IRB.CurrentContext.workspace.binding)
end
