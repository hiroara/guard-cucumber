require "guard/compat/test/helper"

require "guard/cucumber/focuser"

RSpec.describe Guard::Cucumber::Focuser do
  let(:focuser)     { Guard::Cucumber::Focuser }
  let(:focus_tag)   { "@focus" }
  let(:null_device) { RUBY_PLATFORM.index("mswin") ? "NUL" : "/dev/null" }

  let(:dir)      { "features" }
  let(:path)     { "foo.feature" }
  let(:path_two) { "bar.feature" }

  describe ".focus" do
    context "when passed an empty paths list" do
      it "returns false" do
        expect(focuser.focus([], "@focus")).to be_falsey
      end
    end

    context "when passed a paths argument" do
      let(:file) do
        StringIO.new <<-EOS
          @focus
          Scenario: Foo
          Given bar
          Scenario: Bar
          Given focus lorem
          @focus
          Scenario: Ipsum
          Given dolor
        EOS
      end

      let(:file_two) do
        StringIO.new <<-EOS
          @focus
          Scenario: Lorem
          Given ipsum
          @focus
          Scenario: Bar
          Given lorem
          Scenario: Dolor
          Given sit focus
        EOS
      end

      before do
        expect(File).to receive(:open).with(path, "r").and_yield(file)
        expect(File).to receive(:open).with(path_two, "r").and_yield(file_two)
      end

      it "returns an array of paths updated to focus on line numbers" do
        paths = [path, path_two]

        expect(focuser.focus(paths, focus_tag)).to eql([
                                                         "foo.feature:1:6",
                                                         "bar.feature:1:4"
                                                       ])
      end
    end
  end

  describe ".scan_path_for_focus_tag" do
    context "file with focus tags in it" do
      let(:file) do
        StringIO.new <<-EOS
          @focus
          Scenario: Foo
          Given bar
          Scenario: Bar
          Given lorem
          @focus
          Scenario: Ipsum
          Given dolor
        EOS
      end

      before do
        expect(File).to receive(:open).with(path, "r").and_yield(file)
      end

      it "returns an array of file names with line numbers" do
        expect(focuser.scan_path_for_focus_tag(path, focus_tag)).to eql(["#{path}:1:6"])
      end
    end

    context "file without focus tags in it" do
      let(:file) do
        StringIO.new <<-EOS
          Scenario: Foo
          Given bar
          Scenario: Bar
          Given lorem
          Scenario: Ipsum
          Given dolor
        EOS
      end

      before do
        expect(File).to receive(:open).with(path, "r").and_return(file)
      end

      it "returns an empty array" do
        expect(focuser.scan_path_for_focus_tag(path, focus_tag)).to eql([])
      end
    end

    context "file that is a directory" do
      let(:file) do
        StringIO.new <<-EOS
          @focus
          Scenario: Foo
          Given bar
          Scenario: Bar
          Given lorem
          Scenario: Ipsum
          Given dolor
        EOS
      end

      before do
        expect(File).to receive(:directory?).with(dir).and_return(true)
        expect(Dir).to receive(:glob).with("#{dir}/**/*.feature").and_return([path])
        expect(File).to receive(:open).with(path, "r").and_yield(file)
      end

      it "returns an array of file names with line numbers" do
        expect(focuser.scan_path_for_focus_tag(dir, focus_tag)).to eql(["#{path}:1"])
      end
    end

    context "file that has already a line number" do
      let(:path) { "bar.feature:12" }

      it "returns an empty array" do
        expect(File).not_to receive(:open).with(path, "r")
        expect(focuser.scan_path_for_focus_tag(path, focus_tag)).to eql([])
      end
    end
  end
end
