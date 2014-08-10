require 'redcarpet'
require 'pygments'

module Firebots

  private

  class MarkdownRenderer < Redcarpet::Render::XHTML
    def block_code(code, language)
      Pygments.highlight(code, :lexer => language, :formatter => 'html', :options => {:encoding => 'utf-8'})
    end
  end

  public

  Markdown = Redcarpet::Markdown.new(MarkdownRenderer,
                                     :no_intra_emphasis => true,
                                     :fenced_code_blocks => true,
                                     :lax_spacing => true,
                                     :superscript => true)

  MarkdownCodeSyntaxCSS = Pygments.css

end
