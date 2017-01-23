require "guard/compat/plugin"

module Guard
  class Cucumber < Plugin
    # The Cucumber focuser updates cucumber feature paths to
    # focus on sections tagged with a provided focus_tag.
    #
    # For example, if the `foo.feature` file has the provided focus tag
    # `@bar` on line 8, then the path will be updated using the cucumber
    # syntax for focusing on a section:
    #
    # foo.feature:8
    #
    # If '@bar' is found on lines 8 and 16, the path is updated as follows:
    #
    # foo.feature:8:16
    #
    # The path is not updated if it does not contain the focus tag.
    #
    module Focuser
      class << self
        # Focus the supplied paths using the provided focus tag.
        #
        # @param [Array<String>] paths the locations of the feature files
        # @param [String] focus_tag the focus tag to look for in each path
        # @return [Array<String>] the updated paths
        #
        def focus(paths, focus_tag)
          return false if paths.empty?

          focused_paths = paths.inject([]) do |focused_lines, path|
            focused_lines + scan_path_for_focus_tag(path, focus_tag)
          end
          focused_paths.empty? ? paths : focused_paths
        end

        # Checks to see if the file at path contains the focus tag
        # It will scan all recursive entries if the path is a directory.
        #
        # @param [String] path the file path to search
        # @param [String] focus_tag the focus tag to look for in each path
        # @return [Array<String>] the paths with line numbers that include
        # the focus tag in path
        #
        def scan_path_for_focus_tag(path, focus_tag)
          return [] if path.include?(":")

          paths = File.directory?(path) ? Dir.glob("#{path}/**/*.feature") : [path]

          paths.map do |path|
            line_numbers = scan_focus_tag(path, focus_tag)
            line_numbers.empty? ? nil : ([path] + line_numbers).join(':')
          end.compact
        end

        private

        def scan_focus_tag(path, focus_tag)
          [].tap do |line_numbers|
            File.open(path, "r") do |file|
              while (line = file.gets)
                line_numbers << file.lineno if line.include?(focus_tag)
              end
            end
          end
        end
      end
    end
  end
end
