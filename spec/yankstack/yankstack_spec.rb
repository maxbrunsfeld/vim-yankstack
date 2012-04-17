require "spec_helper"

describe "Yankstack" do
  let(:vim) { Vimbot::Driver.new }
  subject { vim }

  before(:all) { vim.start }
  after(:all)  { vim.stop }
  before { vim.clear_buffer }

  shared_examples "yanking and pasting" do
    before do
      vim.insert "first line<CR>", "second line<CR>", "third line<CR>", "fourth line"
      vim.normal "gg", "yy", "jyy", "jyy", "jyy"
    end

    it "pushes every yanked line to the :Yanks stack" do
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

    describe "pasting a line in visual mode" do
      before do
        vim.normal "$"
        vim.append "<CR>", "fifth line"
        vim.normal "Vp"
      end

      xit "overwrites the selection with the most recently yanked line" do
        vim.line.should == "fourth line"
      end

      xit "moves the previously yanked text to the top of the stack" do
        yanks_output[0].should include "fourth line"
        yanks_output[1].should include "third line"
      end

      xit "moves the the overwritten text to the bottom of the stack" do
        yanks_output[-1].should include "fifth line"
      end

      describe "typing the 'cycle paste' key" do
        before { vim.normal "<M-p>" }
      end
    end
  end

  describe "when the default register is configured normally" do
    it_behaves_like "yanking and pasting"
  end

  describe "when clipboard=unnamed (the default register is the system clipboard)" do
    before { vim.command "set clipboard=unnamed" }

    it_behaves_like "yanking and pasting"
  end

  def yanks_output
    lines = vim.command("Yanks").split("\n")
    lines[1..lines.length]
  end
end


