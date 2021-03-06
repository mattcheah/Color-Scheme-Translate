require "pp"
require 'byebug'

class AtomInputController
    attr_accessor :options
  
    def initialize(directory_path)
          
        @directory_path = directory_path
        if File.exist?("#{@directory_path}/package.json") && File.exist?("#{@directory_path}/index.less")
          @package = File.read("#{@directory_path}/package.json")
        else
          raise "Error: Atom directory needs a package.json file and an index.less file at path in the directory: #{directory_path}"
        end
        @options = {}
        @color_hash = {}
        `coyote '#{@directory_path}/index.less:#{@directory_path}/output.less'`
    end
     
    def parse_input_files

      @base = File.read("#{@directory_path}/output.less")

      get_theme_name
      parse_colors
      get_base_options
 
      puts "done!"
      puts ""

    end

    private
    
    def get_theme_name
      @package.scan(/"name":\s"(.*?)"\,.*?"theme":\s"syntax"/mx) do |m|
        @options[:theme_name] = m[0]
      end
    end

    def parse_colors

      @less = {}

      @base.scan(/^(@.*):\s*(.*);/i) do |m|
        if m[1][0] == "@"
          @less[m[0]] = m[1]
        else
          @color_hash[m[0].underscore.to_sym] = m[1]
        end
        
        print "."
      end
      
      if @less.length > 0
        less_variable_reduce()
      end
      
    end
    
    def less_variable_reduce()
      
      temp_less_var = {}
      @less.each do |key, value|
        
        if @color_hash.has_key?(value.underscore.to_sym)
          @color_hash[key.underscore.to_sym] = @color_hash[value.underscore.to_sym]
          @less.delete(key)
        end
        
        @base.scan(/^#{value}:\s+(.*);$/x) do |m|
          if m
            if m[0][0] == "@"
              temp_less_var[key] = m[0]
            else
              @color_hash[value.underscore.to_sym] = m[0]
              @color_hash[key.underscore.to_sym] = m[0]
              @less.delete(key)
              print "."
            end
          end
        end
        
      end
      
      @less.merge(temp_less_var)
      
      if @less.length > 0
        less_variable_reduce()
      end
    end

    def get_base_options
      
        parse_options = {
          foreground: /atom-text-editor.*?^\s*[^background-]color:\s*(.*?);.*?}/mx,
          background: /atom-text-editor.*?background-color:\s*(.*?);/mx,
          caret: /atom-text-editor.*?\s*cursor\s*{.*?color:\s*(.*?);/mx,
          invisibles: /atom-text-editor.*?invisible-character.*?\{.*?color:\s*(.*?)/mx,
          line_highlight: /\.line-number\.cursor-line.*?\{.*?background-color:\s*(.*?);/mx,
          selection: /\.selection.*?\.region\s*?{.*?color:\s*(.*?);/mx,
          brackets_foreground: /\.bracket-matcher\s*?\.region.*?border-bottom:\s*?[0-9]*px\s*?(?:solid|dotted|dashed)\s+?(.*?);/mx,
          bracket_contents_foreground: /\.bracket-matcher\s*?\.region.*?border-bottom:\s*?[0-9]*px\s*?(?:solid|dotted|dashed)\s+?(.*?);/mx,
          comment_foreground: /\.syntax--comment.*?\{.*?color:\s*(.*?);/mx,
          string_foreground: /^\.syntax--string\s*{\n?\s+color:\s*(.*?);$/mx,
          number_foreground: /\.syntax--constant.*?syntax--numeric.*?\{.*?color:\s*(.*?);/mx,
          build_in_constant_foreground: /\.syntax--constant.*?\{.*?color:\s*(.*?);/mx,
          user_defined_constant_foreground: /\.syntax--constant.*?\{.*?color:\s*(.*?);/mx,
          variable_foreground: /\.syntax--variable.*?\{.*?color:\s*(.*?);/mx,
          keyword_foreground: /\.syntax--keyword.*?\{.*?color:\s*(.*?);/mx,
          storage_foreground: /\.syntax--storage.*?\.syntax--modifier.*?\{.*?color:\s*(.*?);/mx,
          storage_type_foreground: /\.syntax--storage.*?\{.*?color:\s*(.*?);/mx,
          entity_name_foreground: /^\.syntax--entity.*?color:\s*(.*?);/mx,
          function_argument_foreground: /syntax--support.*?\{.*?color:\s*(.*?);/mx,
          tag_name_foreground: /\.syntax--entity\.syntax--name\.syntax--tag.*?{.*?color:\s*(.*?);/mx,
          tag_attribute_foreground: /\.syntax--other\.syntax--attribute-name.*?\{.*?color:\s*(.*?);/mx,
          function_call_foreground: /syntax--function.*?\{.*?color:\s*(.*?);.*?\}/mx,
          library_function_foreground: /syntax--function.*?\{.*?color:\s*(.*?);/mx,
          library_class_type_foreground: /syntax--support\s*\{.*?color:\s*(.*?);/mx,
          invalid_foreground: /syntax--illegal.*?\{.*?color:\s*(.*?);/mx,
          invalid_background: /syntax--illegal.*?\{.*?background-color:\s*(.*?);/mx,
        }
        
        parse_options.each do |key, value|
          
        	color = get_hex_value(@base.match(value))
        	
        	@options[key] = color
        # 	puts "#{key.to_s}: #{color}"
        
        end
        
        
        return @options
    end

    def get_hex_value(options_match)
        if options_match
          if options_match[1][0] == '@'
              return @color_hash[options_match[1].underscore.to_sym]
          else
              return options_match[1]
          end
        end
    end
end