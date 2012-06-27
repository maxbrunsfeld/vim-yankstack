require "spec_helper"

describe "Yankstack" do
  let(:vim) { Vimbot::Driver.new }

  before(:all) do
    vim.start
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

      keys_that_change_register = [
        'cc', 'C',
        'dd', 'D',
        's', 'S',
        'x', 'X',
        'yy', 'Y'
      ]

      keys_that_change_register.each do |key|
        it "pushes to the stack when deleting text with '#{key}'" do
          vim.normal key
          yank_entries[1].should match /1\s+fourth line/
        end
      end

      it "pushes to the stack when overwriting text in select mode" do
        vim.type "V"
        vim.type "<c-g>", "this overwrites the last line"
        yank_entries[0].should include "line to delete"
        yank_entries[1].should include "fourth line"
      end
    end

    context "in normal mode" do
      describe "pasting a line with 'p'" do
        before { vim.normal "p" }

        it "pastes the most recently yanked line" do
          vim.line_number.should == 5
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

      describe "typing the `substitute_older_paste` key without pasting first" do
        before { vim.type "<M-p>" }

        it "pastes the most recently yanked line" do
          vim.line_number.should == 5
          vim.line.should == "fourth line"
        end

        describe "typing the 'cycle paste' key" do
          before { vim.normal "<M-p>" }

          it "replaces the pasted text with the previously yanked text" do
            vim.line.should == "third line"
          end
        end
      end

      describe "typing the `substitute_newer_paste` key without pasting first" do
        before { vim.type "<M-P>" }

        it "pastes the most recently yanked line" do
          vim.line_number.should == 5
          vim.line.should == "fourth line"
        end

        describe "typing the 'cycle paste' key" do
          before { vim.normal "<M-p>" }

          it "replaces the pasted text with the previously yanked text" do
            vim.line.should == "third line"
          end
        end
      end
    end

    context "in visual mode, with text highlighted" do
      before do
        vim.normal "A<CR>", "line to overwrite"
        vim.normal "V"
      end

      describe "pasting a line with 'p'" do
        before do
          vim.type "p"
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

      describe "typing the `substitute_older_paste` key without pasting first" do
        before { vim.type "<M-p>" }

        it "overwrites the selection with the most recently yanked line" do
          vim.line_number.should == 5
          vim.line.should == "fourth line"
        end
      end

      describe "typing the `substitute_newer_paste` key without pasting first" do
        before { vim.type "<M-P>" }

        it "overwrites the selection with the most recently yanked line" do
          vim.line_number.should == 5
          vim.line.should == "fourth line"
        end
      end
    end

    describe "pasting a line in insert mode using `substitute_older_paste`" do
      before { vim.normal "A", "<M-p>" }

      it "pastes the most recently yanked text" do
        vim.line_number.should == 5
        vim.line.should == "fourth line"
      end

      describe "typing the 'cycle paste' key" do
        before { vim.type "<M-p>" }

        it "replaces the pasted text with the previously yanked text" do
          vim.line_number.should == 5
          vim.line.should == "third line"
        end

        it "stays in insert mode" do
          vim.should be_in_insert_mode
        end

        it "rotates the previously yanked text to the top of the yank stack" do
          yank_entries[0].should include 'third line'
          yank_entries[1].should include 'second line'
          yank_entries[2].should include 'first line'
          yank_entries[-1].should include 'fourth line'
        end

        it "rotates through the yanks when pressed multiple times" do
          vim.type "<M-p>"
          vim.line_number.should == 5
          vim.line.should == "second line"

          vim.type "<M-p>"
          vim.line_number.should == 5
          vim.line.should == "first line"

          vim.type "<M-P>"
          vim.line_number.should == 5
          vim.line.should == "second line"

          vim.type "<M-P>"
          vim.line_number.should == 5
          vim.line.should == "third line"

          vim.type "<M-P>"
          vim.line_number.should == 5
          vim.line.should == "fourth line"
        end
      end
    end

  end

  describe "when using the normal default register" do
    it_has_behavior "yanking and pasting"
  end

  describe "when using the system clipboard as the default register" do
    before { vim.set "clipboard", "unnamed" }

    it_has_behavior "yanking and pasting"
  end

  def yank_entries
    @yank_entries ||= vim.command("Yanks").split("\n")[1..-1]
  end
end

