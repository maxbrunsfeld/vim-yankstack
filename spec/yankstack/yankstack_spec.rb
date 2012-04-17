require "spec_helper"

describe "Yankstack" do
  let(:vim) { Vimbot::Driver.new }
  subject { vim }

  before(:all) { vim.start }
  after(:all)  { vim.stop }

  before do
    vim.clear_buffer
    vim.insert "first line<CR>", "second line<CR>", "third line<CR>", "fourth line"
    vim.normal "gg"
  end

  describe "yanking a line" do
    before { vim.normal "yy" }

    it "pushes that line to the :Yanks stack" do
      yanks_output[0].should match /^0\s+first line/
    end

    describe "yanking more lines" do
      before do
        vim.normal "jyy", "jyy", "jyy"
      end

      it "pushes those lines to the :Yanks stack" do
        yanks_output[0].should match /0\s+fourth line/
        yanks_output[1].should match /1\s+third line/
        yanks_output[2].should match /2\s+second line/
        yanks_output[3].should match /3\s+first line/
      end

      describe "pasting a line in normal mode" do
        before { vim.normal "p" }

        it "pastes the most recently yanked line" do
          vim.line.should == "fourth line"
        end

        describe "typing the 'cycle paste' key" do
          before { vim.normal "<M-p>" }

          it "replaces the pasted text with the previously yanked text" do
            vim.line.should == "third line"
          end

          it "rotates the previously yanked text to the top of the yank stack" do
            yanks_output[0].should include 'third line'
            yanks_output[1].should include 'second line'
            yanks_output[2].should include 'first line'
            yanks_output[-1].should include 'fourth line'
          end

          it "rotates through the yanks when pressed multiple times" do
            vim.normal "<M-p>"
            vim.line.should == "second line"
            vim.normal "<M-p>"
            vim.line.should == "first line"

            vim.normal "<M-P>"
            vim.line.should == "second line"
            vim.normal "<M-P>"
            vim.line.should == "third line"
            vim.normal "<M-P>"
            vim.line.should == "fourth line"
          end
        end
      end
    end
  end

  def yanks_output
    lines = vim.command("Yanks").split("\n")
    lines[1..lines.length]
  end
end
