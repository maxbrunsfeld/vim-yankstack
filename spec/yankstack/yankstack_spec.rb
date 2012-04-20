require "spec_helper"

describe "Yankstack" do
  let(:vim) { Vimbot::Driver.new }
  subject { vim }

  before(:all) do
    vim.start
    vim.set "nocompatible"
    vim.set "runtimepath+=#{PLUGIN_ROOT}"
    vim.runtime "plugin/yankstack.vim"
  end
  after(:all)   { vim.stop }
  before(:each) { vim.clear_buffer }

  shared_examples "yanking and pasting" do
    before do
      vim.insert "first line<CR>", "second line<CR>", "third line<CR>", "fourth line"
      vim.normal "gg", "yy", "jyy", "jyy", "jyy"
    end

    it "pushes every yanked line to the :Yanks stack" do
      yank_entries[0].should match /0\s+fourth line/
      yank_entries[1].should match /1\s+third line/
      yank_entries[2].should match /2\s+second line/
      yank_entries[3].should match /3\s+first line/
    end

    describe "yanking with different keys" do
      before do
        vim.normal "A", "<CR>", "line to delete", "<Esc>", "^"
      end

      KEYS_THAT_CHANGE_REGISTER = [
        'cc', 'C',
        'dd', 'D',
        'x', 'X',
        'Y',
        'S'
      ]

      KEYS_THAT_CHANGE_REGISTER.each do |key|
        it "pushes to the stack when deleting text with '#{key}'" do
          vim.normal key
          yank_entries[1].should match /1\s+fourth line/
        end
      end
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
          yank_entries[0].should include 'third line'
          yank_entries[1].should include 'second line'
          yank_entries[2].should include 'first line'
          yank_entries[-1].should include 'fourth line'
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
        vim.append "<CR>", "line to overwrite"
        vim.normal "Vp"
      end

      it "overwrites the selection with the most recently yanked line" do
        vim.line.should == "fourth line"
      end

      it "moves the the overwritten text to the bottom of the stack" do
        yank_entries[0].should include "fourth line"
        yank_entries[1].should include "third line"
        yank_entries[2].should include "second line"
        yank_entries[-1].should include "line to overwrite"
      end

      describe "typing the 'cycle older paste' key" do
        before { vim.normal "<M-p>" }

        it "replaces the pasted text with the previously yanked text" do
          vim.line.should == "third line"
        end

        it "moves the previously yanked text to the top of the stack" do
          yank_entries[0].should include "third line"
          yank_entries[1].should include "second line"
          yank_entries[2].should include "first line"
          yank_entries[-2].should include "line to overwrite"
          yank_entries[-1].should include "fourth line"
        end

        describe "typing the 'cycle newer paste' key" do
          before { vim.normal "<M-P>" }

          it "replaces the pasted text with the previously yanked text" do
            vim.line.should == "fourth line"
          end

          it "moves the previously yanked text to the top of the stack" do
            yank_entries[0].should include "fourth line"
            yank_entries[1].should include "third line"
            yank_entries[2].should include "second line"
            yank_entries[3].should include "first line"
            yank_entries[-1].should include "line to overwrite"
          end
        end
      end
    end
  end

  describe "when using the normal default register" do
    it_has_behavior "yanking and pasting"
  end

  describe "when using the system clipboard as the default register" do
    before { vim.command "set clipboard=unnamed" }

    # it_has_behavior "yanking and pasting"
  end

  def yank_entries
    @yank_entries ||= vim.command("Yanks").split("\n")[1..-1]
  end
end

